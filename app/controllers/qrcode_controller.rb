class QrcodeController < ApplicationController
  session :off, :only => [ :image ]

  before_filter :default_qrurl
  rescue_from RQRCode::QRCodeRunTimeError, :with => :qrcode_err
    
  def create
    @advance = params[:advance]
    session[:msg] = @msg

    @qrimage = QRImage.find_or_create(params)

    if request.xhr?
      @imgurl = "#{@createurl}?version=#{@qrimage.version}&ecc=#{@qrimage.ecc}&msg=#{@qrimage.message}"
      @qrurl = url_for(:action => :image, :md5 => @qrimage.md5)

      render :update do |page|
        page.replace_html  'qrcode', :partial => 'qrcode/qrcode', :locals => {:qrurl => @qrurl, :imgurl => @imgurl}
        page.visual_effect :highlight, 'qrcode'
      end
    else
      if @qrimage
        redirect_to :action => :image, :md5 => @qrimage.md5
      else 
        redirect_to @qrurl
      end
    end
  end
  
  def preview
    @version = params[:version].nil? ? 6 : params[:version].to_i
    @ecc = params[:ecc].to_sym rescue :q
    @msg = params[:msg]
    session[:msg] = @msg

    @qrimage = QRImage.find_or_create(params)

    @imgurl = "#{@createurl}?version=#{@qrimage.version}&ecc=#{@qrimage.ecc}&msg=#{@qrimage.message}"
    @qrurl = url_for(:action => :image, :md5 => @qrimage.md5)

    @advance = true
    
    render :action => :help
  end
  
  def help
    @advance = params[:advance]
    @msg = params[:msg] || session[:msg]
  end

  def image
    @qrimage = QRImage.find_by_md5(params[:md5])
	if @qrimage
      headers['Cache-Control'] = 'public; max-age=2592000' # cache image for a month
      send_data @qrimage.data, :filename => @qrimage.filename, :disposition => 'inline', :type => "image/png"
    else
      render :nothing => true, :status => 404
    end
  end

  protected
    def default_qrurl
      @createurl = url_for(:only_path => false, :controller => :qrcode, :action => :create)
      @advance = true 
	  @msg = url_for(:only_path => false, :controller => :qrcode, :action => :help)

	  @default_qrimage = QRImage.find_or_create(:message => @msg)
      @qrurl = url_for(:action => :image, :md5 => @default_qrimage.md5)
	  @imgurl = @qrurl
    end

    def qrcode_err(exception)
      msg = exception.message

      if msg =~ %r{overflow}
        flash[:error] = "Sorry, your message is too long. <br/>Try a higher QRCode level, lower error correction level or a shorter message."
        @advance = true
      elsif msg =~ %r{bad rsblock}
        flash[:error] = "Unsupported version. We only supports 1-10 level"
      else
        flash[:error] = "Error encoding QRCode: " + exception.message
      end
      
      if request.xhr?
        render :update do |page|
          page.redirect_to url_for(:overwrite_params => {:action => :help, :advance => true})
        end
      else
        render :action => :help
      end
    end
end
