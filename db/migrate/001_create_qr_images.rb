class CreateQrImages < ActiveRecord::Migration
  def self.up
    create_table :qr_images do |t|
      t.string :md5, :null => false
      t.string :ecc
      t.integer :version, :default => 6
      t.string :message
      t.timestamps
    end
  end

  def self.down
    drop_table :qr_images
  end
end
