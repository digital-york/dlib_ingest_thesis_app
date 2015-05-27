class UploadedFile < ActiveRecord::Base
  belongs_to :thesis

  # dragonfly accessor for uploaded file(s)
  dragonfly_accessor :uf

  validates :uf, presence: true
  validates_size_of :uf, maximum: 500.megabytes,
                    message: "should be no more than 500 MB", if: :uf_changed?
  validates_property :format, of: :uf, in: [:jpeg, :jpg, :png, :bmp, :pdf, :doc, :docx], case_sensitive: false,
                    message: "should be either .jpeg, .jpg, .png, .bmp, .pdf, .doc, .docx", if: :uf_changed?

end
