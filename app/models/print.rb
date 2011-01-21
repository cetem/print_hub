class Print < ActiveRecord::Base
  # Callbacks
  before_validation :assign_fake_job_ids
  before_save :print_all_jobs

  # Restricciones
  validates :printer, :presence => true
  validates :printer, :length => { :maximum => 255 }, :allow_nil => true,
    :allow_blank => true
  validates_each :print_jobs do |record, attr, value|
    if value.reject { |pj| pj.marked_for_destruction? }.empty?
      record.errors.add attr, :blank
    end
  end

  # Relaciones
  belongs_to :user
  belongs_to :customer
  has_many :print_jobs, :dependent => :destroy

  accepts_nested_attributes_for :print_jobs, :allow_destroy => true

  def initialize(attributes = nil)
    super(attributes)

    self.user = UserSession.find.try(:user) || self.user rescue self.user
    self.print_jobs.build if self.print_jobs.empty?
  end

  def assign_fake_job_ids
    # Para que valide, luego se asigna el verdadero ID en print_all_jobs
    self.print_jobs.each { |pj| pj.job_id ||= 1 }
  end

  def print_all_jobs
    self.print_jobs.each do |pj|
      job = Cups::PrintJob.new(pj.document.file.path, self.printer)

      job.print
      
      pj.job_id = job.job_id
    end
  end
end