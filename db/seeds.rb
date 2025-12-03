# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create Credit Packages
credit_packages = [
  { name: "Starter Pack", credits: 20, price_usd: 19.00, description: "Perfect for trying out the platform" },
  { name: "Popular Pack", credits: 50, price_usd: 39.00, description: "Most popular choice - best value" },
  { name: "Pro Pack", credits: 100, price_usd: 69.00, description: "For power users" },
  { name: "Ultimate Pack", credits: 250, price_usd: 149.00, description: "Maximum credits at the best rate" }
]

credit_packages.each do |package|
  CreditPackage.find_or_create_by!(name: package[:name]) do |cp|
    cp.credits = package[:credits]
    cp.price_usd = package[:price_usd]
    cp.description = package[:description]
    cp.active = true
  end
end

puts "Created #{CreditPackage.count} credit packages"
