class DocumentTagRelation < ApplicationModel
  has_paper_trail

  belongs_to :tag
  belongs_to :document
end
