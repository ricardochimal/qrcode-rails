class QRImage < ActiveRecord::Base
  before_save :set_defaults

  validates_presence_of :md5
  validates_uniqueness_of :md5

  def set_defaults
  	self.version = self.version.to_i
    self.version = 6 unless version >= 1 and version <= 10
    self.ecc = self.ecc.to_s
	self.ecc = 'q' unless [ 'l', 'm', 'q', 'h' ].include?(self.ecc)
    self.md5 = QRImage.image_hash(self.version, self.ecc, self.message)
  end

  def data
    qrcode = RQRCode::QRCode.new(self.message, :size => self.version, :level => self.ecc.to_sym)
    qrcode.to_s
  end

  def filename
    "#{md5}.png"
  end

  def self.preview(params)
    q = QRImage.new
	q.message = params[:message] || params[:msg]
	q.ecc = params[:ecc]
	q.version = params[:version]
	q.set_defaults
	q
  end

  def self.image_hash(version, ecc, message)
    Digest::MD5.hexdigest("#{version}-#{ecc}-#{message}")
  end

  def self.find_or_create(params)
    q = QRImage.preview(params)
    existing_image = QRImage.find_by_md5(q.md5)
    return existing_image if existing_image
    q.save!
    q	
  end
end
