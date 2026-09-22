class ReferencePage < ActiveRecord::Base
  validates :path, presence: true, uniqueness: true
  validate :content_matches_template_contract

  def content_matches_template_contract
    file = ReplicaController::MANIFEST.fetch("pages")[path]
    return errors.add(:path, "is not an imported page") unless file
    schema = JSON.parse(Rails.root.join("replica", "schemas", file.sub(/\.html\z/, ".json")).read)
    unless fields.is_a?(Hash) && fields.keys.sort == schema.keys.sort
      return errors.add(:fields, "must contain the template's declared content fields")
    end
    fields.each do |key, value|
      unless value.is_a?(String)
        errors.add(:fields, "must contain plain strings"); next
      end
      case schema.fetch(key).fetch("kind")
      when "asset", "background"
        errors.add(:fields, "has an invalid local media reference") unless value.match?(%r{\A/replica-assets/[a-zA-Z0-9_.-]+\z})
      when "link"
        errors.add(:fields, "has an unsafe link") unless value.match?(%r{\A(?:/(?!/)|\#|https://|mailto:|tel:)})
      end
    end
  end
end
