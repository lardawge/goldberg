module Goldberg
  class ContentPagesController < ApplicationController
    include Goldberg::Controller
  
    # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
    verify :method => :post, :only => [ :destroy, :create, :update ],
    :redirect_to => { :action => :list }

    def index
      list
      render :action => 'list'
    end

    def list
      @content_pages = ContentPage.find(:all, :order => 'name')
    end

    def show
      @content_page = ContentPage.find(params[:id])
      foreign
    end

    def view
      @content_page = ContentPage.find_by_name(params[:page_name].join('/'))
      if not @content_page
        if Goldberg.settings
          @content_page = ContentPage.find(Goldberg.settings.not_found_page_id)
        else
          @content_page = ContentPage.new(:id => nil, 
                                          :content => '(no such page)')
        end
      end
    end

    def view_default
      if Goldberg.settings
        @content_page = ContentPage.find(Goldberg.settings.site_default_page_id)
      else
        @content_page = ContentPage.new(:id => nil, 
                                        :content => '(Site not configured)')
      end
    end

    def new
      @content_page = ContentPage.new
      foreign
      @content_page.markup_style = @markup_styles.first
    end

    def create
      @content_page = ContentPage.new(params[:content_page])
      if @content_page.save
        flash[:notice] = 'ContentPage was successfully created.'
        Role.rebuild_cache
        redirect_to :action => 'list'
      else
        foreign
        render :action => 'new'
      end
    end

    def edit
      @content_page = ContentPage.find(params[:id])
      foreign()
    end

    def update
      @content_page = ContentPage.find(params[:id])
      if @content_page.update_attributes(params[:content_page])
        flash[:notice] = 'ContentPage was successfully updated.'
        Role.rebuild_cache
        redirect_to :action => 'show', :id => @content_page
      else
        foreign
        render :action => 'edit'
      end
    end

    def destroy
      @content_page = ContentPage.find(params[:id])
      foreign
      
      if @menu_items.length == 0 and not @system_pages
        @content_page.destroy
        Role.rebuild_cache
        redirect_to :action => 'list'
      else
        flash.now[:error] = "Cannot delete this Content Page as it has dependants (see below)"
        render :action => 'show'
      end
    end

    # Entry point for any FCKeditor file operations.
    def fck_filemanager
      @command = params['Command']
      @type = (params['Type'] == 'File' ? '' : params['Type'])
      @subdir = params['CurrentFolder']
      @path = File.join('/files', @type, @subdir)
      @dir = File.join(RAILS_ROOT, 'public', @path)

      @incl_files = false
      
      case @command
      when 'GetFolders'
        fck_files
      when 'GetFoldersAndFiles'
        @incl_files = true
        fck_files
      when 'CreateFolder'
        fck_create_folder
      when 'FileUpload'
        fck_file_upload
      else  # huh?
        render :nothing => true, :status => 400
      end
    end

    # Invoked by FCKeditor spell check.  Returns a HTML document
    # containing Javascript with spelling suggestions.
    def fck_speller_pages
      @textinputs = params['textinputs'][0]
      @suggestions = ContentPage.speller_pages( CGI.unescape(@textinputs) )
      render :action => 'fck_speller_pages', :layout => false
    end

    protected

    def fck_files
      @dirs = []
      @files = {}
      if File.directory? @dir
        Dir.glob( File.join(@dir, '*') ) do |file|
          if File.directory? file
            @dirs << File.basename(file)
          else
            @files[File.basename(file)] = File.stat(file).size / 1024
          end
        end
      end

      render :partial => 'fck_files'
    end

    def fck_create_folder
      @newdir = File.join(@dir, params['NewFolderName'])
      @error = 0
      if not ( File.directory?(@dir) and File.writable?(@dir) )
        @error = 103  # "You have no permissions to create the folder."
      elsif ( File.exists?(@newdir) )
        @error = 101  # "Folder already exists."
      elsif ( params['NewFolderName'].length == 0 or
              params['NewFolderName'] =~ /[\/\\:\'\"]/ )
        @error = 102  # "Invalid folder name."
      else  # New directory will *probably* be okay.
        begin
          Dir.mkdir @newdir
        rescue
          @error = 110  # "Unknown error creating folder."
        end
      end

      render :partial => 'fck_create_folder'
    end

    # This method needs better handling: needs to be made more robust,
    # and compliant with the spec at
    # http://fckeditor.wikiwikiweb.de/Developer's_Guide/Participating/Server_Side_Integration#Upload
    def fck_file_upload
      @mime_file = params['NewFile']
      @file_name = @mime_file.original_filename
      @file_url = File.join(@path, @file_name)
      @new_file = File.join(@dir, @file_name)
      File.open(@new_file, 'wb') do |file|
        FileUtils.copy_stream(@mime_file, file)
      end

      render :text => <<-END
<script type="text/javascript">
    window.parent.frames['frmUpload'].OnUploadCompleted(0, '#{@file_url}', '#{@file_name}', '');
</script>
END
    end
    
    def foreign
      @markup_styles = ContentPage.markup_styles
      @permissions = Permission.find(:all, :order => 'name')
      if @content_page.id
        @menu_items = MenuItem.find(:all,
                                    :order => 'label',
                                    :conditions => ['content_page_id=?', 
                                                    @content_page.id])
        @system_pages = Goldberg.settings.system_pages @content_page.id
      end
    end

  end
end
