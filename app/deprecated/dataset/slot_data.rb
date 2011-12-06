# == Schema Information
#
# Table name: dataset_slot_data
#
#  id         :integer(4)      not null, primary key
#  dataset_id :integer(4)
#  slot_id    :integer(4)
#  conversion :float
#  dynamic    :boolean(1)
#

class Dataset::SlotData < ActiveRecord::Base
  include Dataset::TouchOnUpdate

  belongs_to :dataset
  belongs_to :slot
  
  validates :dataset, :presence => true
  validates :slot, :presence => true

  def dataset_key
    Qernel::Slot.compute_dataset_key(slot_id)
  end

  def dataset_attributes
    Qernel::Slot::DATASET_ATTRIBUTES.inject({}) {|hsh, key| hsh.merge key => self[key] }
  end
end