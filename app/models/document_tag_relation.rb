class DocumentTagRelation < ApplicationModel
  has_paper_trail

  belongs_to :tag, optional: true
  belongs_to :document, optional: true
end
