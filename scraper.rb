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
    current_members.map do |mem|
      known = parties.select { |party| party[:name].include? mem[:party] }
      mem[:party_id] = known.first[:id] if known.size == 1
      mem
    end
  end

  field :parties do
    parties_table.xpath('.//tr[td]').map { |tr| fragment(tr => PartyRow).to_h }
  end

  private

  def current_members
    current_members_table.xpath('.//tr[td]').map { |tr| fragment(tr => CurrentMemberRow).to_h }
  end

  def current_members_table
    noko.xpath('//table[.//caption[contains(., "Народні депутати VIII скликання")]]')
  end

  def parties_table
    noko.xpath('//table[.//th[contains(., "1-й номер")]]')
  end
end

class CurrentMemberRow < Scraped::HTML
  field :name do
    name_link.map(&:text).map(&:tidy).first
  end

  field :id do
    name_link.first&.attr('wikidata')
  end

  field :party do
    tds[1].text.tidy
  end

  field :start_date do
    tds[6].text.split('.').reverse.map { |str| '%02d' % str.to_i }.join('-')
  end

  private

  def tds
    noko.css('td')
  end

  def name_link
    tds[2].css('a')
  end
end

class PartyRow < Scraped::HTML
  field :name do
    name_link.map(&:text).map(&:tidy).first
  end

  field :id do
    name_link.first&.attr('wikidata')
  end

  private

  def tds
    noko.css('td')
  end

  def name_link
    tds[1].css('a')
  end
end

url = URI.encode 'https://uk.wikipedia.org/wiki/Верховна_Рада_України_VIII_скликання'
Scraped::Scraper.new(url => MembersPage).store(:members, index: %i[name party])
