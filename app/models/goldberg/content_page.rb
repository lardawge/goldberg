require 'cgi'
# Load RedCloth if available
begin require 'redcloth' rescue nil end

module Goldberg
  class ContentPage < ActiveRecord::Base
    include GoldbergModel
  
    validates_presence_of :name, :title, :permission_id
    validates_uniqueness_of :name
    attr_accessor :content_html

    class << self
      def markup_styles
        if not @markup_styles
          @markup_styles = []
          # If FCKeditor is installed, allow it.
          if File.directory?(File.join RAILS_ROOT, 'public', 'fckeditor')
            @markup_styles << 'FCKeditor'
          end
          # These are the basic styles.
          @markup_styles += ['Raw HTML', 'Plain text']
          # If redcloth is available add Textile and Markdown,
          # otherwise trap the exception.
          begin
            RedCloth
            @markup_styles += ['Textile', 'Markdown']
          rescue MissingSourceFile
            nil
          end
        end
        return @markup_styles
      end
    end  # class << self

    def self.find_for_permission(p_ids)
      if p_ids and p_ids.length > 0
        return find(:all, 
                    :conditions => ['permission_id in (?)', p_ids],
                    :order => 'name')
      else
        return Array.new
      end
    end

    def self.speller_pages(text)
      opts =  '-a --encoding=utf-8 -H 2>&1'
      if RUBY_PLATFORM =~ /mswin/i
        cmd = '"C:\Program Files\aspell\bin\aspell" ' + opts
      else
        cmd = "aspell #{opts}"
      end

      results = []
      IO.popen(cmd, 'r+') do |io|
        io.puts text
        io.close_write
        while not io.eof?
          line = io.readline.chomp
          if line =~ /^\&/
            parts = line.split(' ', 5)
            word = parts[1]
            suggestions = parts[4].split(', ').collect do |suggestion|
              "'#{javascript_esc(suggestion)}'"
            end
            results << [javascript_esc(word), suggestions.join(', ')] 
          end
        end
      end

      return results
    end
    
    def url
      return "/#{self.name}"
    end
    
    
    def content=(new_content)
      write_attribute(:content, new_content)
      self.content_cache = nil
    end


    def before_save
      self.content_cache = self.markup_content
    end


    def content_html
      if self.content_cache and self.content_cache.length > 0
        return self.content_cache
      else
        return self.markup_content
      end
    end

    
    protected

    def self.javascript_esc(string)
      string.gsub(/'/, "\\'")
    end
    
    def markup_content
      content_html = nil
      
      case self.markup_style
      when 'Plain text'
        content_html = "<pre class=\"plain_text\">#{ CGI::escapeHTML(self.content) }</pre>"
          
      when 'Textile'
        begin
          content_html = RedCloth.new(self.content).to_html(:textile)
        rescue
          nil
        end
          
      when 'Markdown'
        begin
          content_html = RedCloth.new(self.content).to_html(:markdown)
        rescue
          nil 
        end

      end

      # If none of the above, then raw content.
      content_html ||= self.content
    end
    
  end
end
