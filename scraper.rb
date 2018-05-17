#!/bin/env ruby
# frozen_string_literal: true

require 'pry'
require 'scraped'
require 'scraperwiki'
require 'wikidata_ids_decorator'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class MembersPage < Scraped::HTML
  decorator WikidataIdsDecorator::Links

  field :members do
    member_table.xpath('.//tr[td]').map { |tr| fragment(tr => MemberRow).to_h }
  end

  private

  def member_table
    noko.xpath('//table[.//caption[contains(., "Народні депутати VIII скликання")]]')
  end
end

class MemberRow < Scraped::HTML
  field :name do
    name_link.map(&:text).map(&:tidy).first
  end

  field :id do
    name_link.first&.attr('wikidata')
  end

  field :party do
    tds[1].text.tidy
  end

  # TODO: convert this to a date
  field :start_date do
    tds[6].text
  end

  private

  def tds
    noko.css('td')
  end

  def name_link
    tds[2].css('a')
  end
end

url = URI.encode 'https://uk.wikipedia.org/wiki/Верховна_Рада_України_VIII_скликання'
Scraped::Scraper.new(url => MembersPage).store(:members, index: %i[name party])
