class QrcodeController < ApplicationController
  QRCODE_BASE_URL = '/images/qrcode'
  QRCODE_BASE_PATH = "#{RAILS_ROOT}/public#{QRCODE_BASE_URL}"
  before_filter :default_qrurl
  rescue_from RQRCode::QRCodeRunTimeError, :with => :qrcode_err
    
  def create    
    @version = params[:version].nil? ? 6 : params[:version].to_i
    @ecc = params[:ecc].to_sym rescue :q
    @msg = params[:msg]
    @advance = params[:advance]
    
    @qrurl = @msg
    @imgurl = "#{@createurl}?msg=#{@msg}"
    
    @filename = Digest::MD5.hexdigest("#{@version}-#{@ecc}-#{@msg}")      
    fullpath = "#{QRCODE_BASE_PATH}/#{@filename}.png"
    
    unless File.exists?(fullpath)
      qrcode = RQRCode::QRCode.new(@msg, :size => @version, :level => @ecc)
      qrcode.save_as_png(fullpath, 4)
    end

    if request.xhr?
      render :update do |page|
        page.replace_html  'qrcode', :partial => 'qrcode/qrcode', :locals => {:qrurl => @msg, :imgurl => "#{QRCODE_BASE_URL}/#{@filename}.png"}
        page.visual_effect :highlight, 'qrcode'
      end
    else
      redirect_to "#{QRCODE_BASE_URL}/#{@filename}.png"
    end
  end
  
  def preview
    @msg = params[:msg]
    @advance = true
    @qrurl = @msg
    @imgurl = "#{@createurl}?msg=#{@msg}"
    
    render :action => :help
  end
  
  def help
    @advance = params[:advance]
    @msg = params[:msg]
  end

  protected
    def default_qrurl
      @createurl = url_for(:only_path => false, :controller => :qrcode, :action => :create)
      @qrurl = url_for(:only_path => false, :controller => :qrcode, :action => :help)
      @imgurl = "#{@createurl}?msg=#{url_for(:only_path => false, :controller => :qrcode, :action => :help)}"
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
