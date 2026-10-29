#!/usr/bin/env ruby
# frozen_string_literal: true

# sync_readings.rb
#
# Converts the Obsidian vault (git submodule at _readings_src) into a Jekyll
# collection under _readings/, so the paper notes can be rendered by Jekyll.
#
# It:
#   * copies each top-level category's *.md notes (Policy/VLA/World-Model/Data)
#   * maps Obsidian embeds (![[image.ext]]) and relative <img> tags to the
#     site's asset path, copying referenced images into assets/readings/<cat>/
#   * rewrites [[internal links]] to real note URLs when resolvable
#   * sanitizes filenames (spaces, '*') into URL-safe slugs
#   * generates one index page per category (Dataview-like HTML table) and a
#     top-level overview page at /readings/

require "yaml"
require "date"
require "fileutils"
require "cgi"
require "strscan"

ROOT = File.expand_path("..", __dir__)
SRC = File.join(ROOT, "_readings_src")
DST = File.join(ROOT, "_readings")
ASSET_DST = File.join(ROOT, "assets", "readings")

CATEGORIES = %w[Policy VLA World-Model Data].freeze

def safe_slug(name)
  base = File.basename(name, ".md")
  base = base.tr(" .*&/\\", "-")
  base = base.gsub(/-+/, "-").gsub(/\A-|-\z/, "")
  base.empty? ? "note" : base
end

def build_note_index
  index = {}
  CATEGORIES.each do |cat|
    dir = File.join(SRC, cat)
    next unless Dir.exist?(dir)
    Dir.glob(File.join(dir, "*.md")).each do |f|
      name = File.basename(f, ".md")
      index[name] = { "category" => cat, "slug" => safe_slug(name), "file" => f }
    end
  end
  index
end

def copy_asset(cat, asset_name)
  src_path = File.join(SRC, cat, "assets", asset_name)
  return nil unless File.exist?(src_path)

  ext = File.extname(asset_name)
  base = File.basename(asset_name, ext)
  safe_base = base.tr(" .*&/\\", "-")
  safe_base = safe_base.gsub(/-+/, "-").gsub(/\A-|-\z/, "")
  safe_name = "#{safe_base}#{ext}"
  dst_dir = File.join(ASSET_DST, cat)
  FileUtils.mkdir_p(dst_dir)
  FileUtils.cp(src_path, File.join(dst_dir, safe_name))
  "/assets/readings/#{cat}/#{safe_name}"
end

def rewrite_embeds(body, cat)
  # Obsidian embed: ![[image.png]] or ![[image.png|width]]
  body = body.gsub(/!\[\[([^\]|]+)(?:\|[^\]]+)?\]\]/) do
    asset = Regexp.last_match(1).strip
    path = copy_asset(cat, asset)
    path ? "![](#{path})" : "(missing embed: #{asset})"
  end

  # Relative <img src="./assets/x"> tags used by a few notes
  body = body.gsub(%r{(<img[^>]*src=["'])(?:\./)?assets/([^"']+)(["'])}) do
    prefix = Regexp.last_match(1)
    asset = Regexp.last_match(2)
    suffix = Regexp.last_match(3)
    path = copy_asset(cat, asset)
    path ? "#{prefix}#{path}#{suffix}" : Regexp.last_match(0)
  end

  body
end

def rewrite_internal_links(body, note_index)
  body.gsub(/\[\[([^\]|]+)(?:\|[^\]]+)?\]\]/) do
    target = Regexp.last_match(1).strip
    target_base = target.sub(/\.md\z/, "")
    if target.end_with?(".base") || target.include?("#")
      "`#{target}`"
    elsif note_index.key?(target_base)
      meta = note_index[target_base]
      cat = meta["category"].downcase
      "[#{target_base}](/readings/#{cat}/#{meta['slug']}/)"
    else
      "`#{target}`"
    end
  end
end

def read_frontmatter(src_file)
  raw = File.read(src_file, encoding: "UTF-8")
  if raw.start_with?("---\n")
    m = raw.match(/\A---\r?\n(.*?)\r?\n---\r?\n?(.*)\z/m)
    fm = m ? YAML.safe_load(m[1], permitted_classes: [Date, Time]) : {}
    body = m ? m[2] : raw
  else
    fm = {}
    body = raw
  end
  fm = {} unless fm.is_a?(Hash)
  [fm, body]
end

def normalize_markdown_tables(body)
  lines = body.lines
  output = []
  fence = nil
  in_table = false

  lines.each_with_index do |line, index|
    if fence
      output << line
      fence = nil if line.match?(/\A {0,3}#{Regexp.escape(fence[0])}{#{fence.length},}[ \t]*\r?\n?\z/)
      next
    end

    # Kramdown requires blank lines around tables; Obsidian accepts adjacent text.
    # Leave fenced examples untouched so their literal Markdown stays intact.
    if in_table && !line.lstrip.start_with?("|")
      output << "\n" unless line.strip.empty?
      in_table = false
    end

    if (match = line.match(/\A {0,3}(`{3,}|~{3,})/))
      fence = match[1]
    elsif line.lstrip.start_with?("|") &&
          lines[index + 1]&.match?(/\A[ \t]*\|(?:[ \t]*:?-{3,}:?[ \t]*\|)+[ \t]*\r?\n?\z/)
      output << "\n" unless output.empty? || output.last.strip.empty?
      in_table = true
    end

    output << line
  end

  output.join
end

def math_span(tex, display: false)
  # Raw span content bypasses Markdown emphasis, escaping, and smart quotes.
  # Encode pipes as well, so formulas inside table cells stay in one cell.
  escaped = CGI.escapeHTML(tex).gsub("|", "&#124;").gsub("\r", "&#13;").gsub("\n", "&#10;")
  kind, opening, closing = display ? ["display", '\[', '\]'] : ["inline", '\(', '\)']
  %(<span class="math-#{kind}" markdown="0">#{opening}#{escaped}#{closing}</span>)
end

def protect_math(body)
  scanner = StringScanner.new(body)
  output = +""

  until scanner.eos?
    # Keep fenced and inline code examples unchanged.
    if scanner.bol? && (opening = scanner.scan(/ {0,3}(`{3,}|~{3,})[^\n]*(?:\n|\z)/))
      fence = scanner[1]
      output << opening
      until scanner.eos?
        line = scanner.scan(/[^\n]*(?:\n|\z)/)
        output << line
        break if line.match?(/\A {0,3}#{Regexp.escape(fence[0])}{#{fence.length},}[ \t]*\r?\n?\z/)
      end
    elsif (ticks = scanner.scan(/`+/))
      output << ticks
      closing = /(?<!`)#{Regexp.escape(ticks)}(?!`)/
      output << scanner.scan_until(closing) if scanner.rest.match?(closing)
    elsif (escaped = scanner.scan(/\\./m))
      output << escaped
    elsif scanner.peek(2) == "$$"
      if scanner.scan(/\$\$((?:\\.|[^\\])*?)\$\$/m)
        output << math_span(scanner[1], display: true)
      else
        output << scanner.getch
      end
    elsif scanner.scan(/\$((?:\\.|[^\\$\n])+)\$/)
      output << math_span(scanner[1])
    else
      output << scanner.getch
    end
  end

  output
end

def write_note(src_file, cat, slug, note_index)
  fm, body = read_frontmatter(src_file)
  fm["layout"] = "reading"
  fm["category"] = cat
  fm["slug"] = slug
  fm["permalink"] = "/readings/#{cat.downcase}/#{slug}/"
  fm["title"] ||= slug
  fm["year"] ||= ""

  body = rewrite_embeds(body, cat)
  body = rewrite_internal_links(body, note_index)
  body = normalize_markdown_tables(body)
  body = protect_math(body)

  out_path = File.join(DST, cat, "#{slug}.md")
  FileUtils.mkdir_p(File.dirname(out_path))
  dumped = YAML.dump(fm)
  dumped = dumped.sub(/\A---\n/, "")
  File.write(out_path, "---\n#{dumped}---\n\n#{body}")
end

def category_notes(cat, note_index)
  note_index.values.select { |m| m["category"] == cat && File.exist?(m["file"]) }
end

def arxiv_sort_key(row)
  match = row["arxiv_number"].strip.match(/\A(\d{2})(0[1-9]|1[0-2])\.(\d{4,5})(?:v\d+)?\z/i)
  return [0, -match[1].to_i, -match[2].to_i, -match[3].to_i, row["title"].to_s] if match

  [1, -row["year"].to_i, 0, 0, row["title"].to_s]
end

def build_category_index(cat, note_index)
  notes = category_notes(cat, note_index)
  rows = notes.map do |meta|
    fm, = read_frontmatter(meta["file"])
    {
      "alias" => fm["alias"] || meta["slug"],
      "title" => fm["title"] || meta["slug"],
      "year" => fm["year"]&.to_s || "",
      "arxiv_number" => fm["arxiv_number"]&.to_s || "",
      "need_revisit" => !!fm["need_revisit"],
      "tags" => Array(fm["tags"]).join(", "),
      "arxiv_url" => fm["arxiv_url"]&.to_s || "",
      "code_url" => fm["code_url"]&.to_s || "",
      "opt_url" => fm["opt_url"]&.to_s || "",
      "slug" => meta["slug"],
    }
  end
  rows = rows.sort_by { |r| arxiv_sort_key(r) }

  index_path = File.join(DST, cat, "index.md")
  FileUtils.mkdir_p(File.dirname(index_path))
  File.write(index_path, <<~MD)
    ---
    layout: reading
    category: #{cat}
    title: #{cat} Readings
    slug: index
    is_index: true
    permalink: /readings/#{cat.downcase}/
    ---
  MD
  rows
end

def build_overview(note_index, index_rows)
  sections = CATEGORIES.map do |cat|
    count = index_rows[cat].length
    cat_key = cat.downcase
    <<~MD
      ### #{cat} (#{count})

      <table class="readings-overview-table">
        <thead>
          <tr><th>Title</th><th>Alias</th><th>Year</th><th>arXiv</th><th>Tags</th><th>Links</th><th>Need Revisit</th></tr>
        </thead>
        <tbody>
        {% for r in site.data.readings_index["#{cat_key}"] %}
          <tr>
            <td><a href="/readings/#{cat_key}/{{ r.slug }}/">{{ r.title }}</a></td>
            <td>{{ r.alias }}</td>
            <td>{{ r.year }}</td>
            <td>{{ r.arxiv_number }}</td>
            <td>{{ r.tags }}</td>
            <td>
              {% if r.arxiv_url %}<a href="{{ r.arxiv_url }}" target="_blank" rel="noopener">arXiv</a> {% endif %}
              {% if r.code_url %}<a href="{{ r.code_url }}" target="_blank" rel="noopener">Code</a> {% endif %}
              {% if r.opt_url %}<a href="{{ r.opt_url }}" target="_blank" rel="noopener">Opt</a> {% endif %}
            </td>
            <td>{% if r.need_revisit %}<span class="need-revisit"></span>{% endif %}</td>
          </tr>
        {% endfor %}
        </tbody>
      </table>
    MD
  end.join("\n")

  overview = <<~MD
    ---
    layout: reading
    title: Readings
    slug: overview
    is_overview: true
    permalink: /readings/
    ---

    # Robot Policy Readings

    A browsable mirror of the [policy_readings](https://github.com/xiaojxkevin/policy_readings) Obsidian vault. Notes are grouped by topic; the tables below follow the vault's Dataview views.

    #{sections}
  MD
  File.write(File.join(DST, "index.md"), overview)
end

def main
  FileUtils.rm_rf(DST)
  note_index = build_note_index
  index_rows = {}

  CATEGORIES.each do |cat|
    index_rows[cat] = build_category_index(cat, note_index)
    category_notes(cat, note_index).each do |meta|
      write_note(meta["file"], cat, meta["slug"], note_index)
    end
  end

  data_out = {}
  CATEGORIES.each do |cat|
    data_out[cat.downcase] = index_rows[cat]
  end
  FileUtils.mkdir_p(File.join(ROOT, "_data"))
  File.write(File.join(ROOT, "_data", "readings_index.yml"), YAML.dump(data_out))

  build_overview(note_index, index_rows)
  puts "Generated #{note_index.length} notes + 4 category indexes + overview."
end

main if $PROGRAM_NAME == __FILE__
