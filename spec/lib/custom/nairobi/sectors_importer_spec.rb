require "rails_helper"

describe Nairobi::SectorsImporter do
  def import(*rows, header: "sector\tsub_sector")
    file = Tempfile.new(["sectors", ".csv"])
    file.write([header, *rows].join("\n"))
    file.close
    Nairobi::SectorsImporter.new(file.path).import
  end

  it "creates the sectors and their subsectors" do
    importer = import("Health\tClinics", "Health\tHospitals", "Education\tSchools", "Water\t")

    expect(importer.errors).to be_empty
    expect(importer.sectors_created).to eq 3
    expect(importer.sub_sectors_created).to eq 3
    expect(Sector.main.map(&:name)).to eq %w[Education Health Water]
    expect(Sector.find_by!(name: "Health").sub_sectors.map(&:name)).to eq %w[Clinics Hospitals]
    expect(Sector.find_by!(name: "Water").sub_sectors).to be_empty
  end

  it "reuses existing sectors and subsectors ignoring case" do
    health = Sector.create!(name: "Health")
    Sector.create!(name: "Clinics", parent: health)

    importer = import("HEALTH\tclinics", "health\tHospitals")

    expect(importer.errors).to be_empty
    expect(importer.sectors_created).to eq 0
    expect(importer.sub_sectors_created).to eq 1
    expect(health.sub_sectors.map(&:name)).to eq %w[Clinics Hospitals]
  end

  it "accepts comma separated files" do
    importer = import("Health,Clinics", header: "sector,sub_sector")

    expect(importer.errors).to be_empty
    expect(Sector.find_by!(name: "Health").sub_sectors.map(&:name)).to eq ["Clinics"]
  end

  it "reports rows without sector" do
    importer = import("\tClinics", "Health\tHospitals")

    expect(importer.errors).to eq ["Line 2: sector is required"]
    expect(Sector.count).to eq 2
  end

  it "reports missing columns" do
    importer = import("Clinics", header: "sub_sector")

    expect(importer.errors).to eq ["Missing columns: sector"]
  end
end
