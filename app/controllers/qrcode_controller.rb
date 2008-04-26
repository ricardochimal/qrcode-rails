class QrcodeController < ApplicationController
  QRCODE_BASE_URL = '/images/qrcode'
  QRCODE_BASE_PATH = "#{RAILS_ROOT}/public#{QRCODE_BASE_URL}"
  
  rescue_from RQRCode::QRCodeRunTimeError, :with => :qrcode_err
    
  def create
    @version = params[:version].nil? ? 4 : params[:version].to_i
    @ecc = params[:ecc].to_sym rescue :h
    @msg = params[:msg]
    @advance = params[:advance]
    
    filename = Digest::MD5.hexdigest("#{@version}-#{@ecc}-#{@msg}")      
    fullpath = "#{QRCODE_BASE_PATH}/#{filename}.png"
    
    unless File.exists?(fullpath)
      qrcode = RQRCode::QRCode.new(@msg, :size => @version, :level => @ecc)
      qrcode.save_as_png(fullpath, 4)
    end

    redirect_to "#{QRCODE_BASE_URL}/#{filename}.png"
  end
  
  def help
    @advance = params[:advance]
  end

  protected
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

      render :action => :help
    end
end
