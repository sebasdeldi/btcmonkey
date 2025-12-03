# frozen_string_literal: true

module ComponentsHelper
  # Button Component Helper
  def button_classes(variant: 'primary', size: 'base', full: false, html_class: '')
    css_classes = ['btn', "btn-#{variant}"]
    css_classes << "btn-#{size}" if size != 'base'
    css_classes << 'btn-full' if full
    css_classes << html_class if html_class.present?
    css_classes.join(' ')
  end

  # Badge Component Helper
  def badge_classes(variant: 'primary', html_class: '')
    css_classes = ['badge', "badge-#{variant}"]
    css_classes << html_class if html_class.present?
    css_classes.join(' ')
  end

  # Status Badge Helper
  def status_badge_classes(status, html_class: '')
    css_classes = ['status-badge', "status-#{status}"]
    css_classes << html_class if html_class.present?
    css_classes.join(' ')
  end

  # Form Field Helper
  def form_input_classes(type: 'text', html_class: '')
    base_class = case type
                 when 'checkbox' then 'form-checkbox'
                 when 'textarea' then 'form-textarea'
                 else 'form-input'
                 end

    classes = [base_class]
    classes << html_class if html_class.present?
    classes.join(' ')
  end

  # Card Component Helper
  def card_classes(hoverable: false, html_class: '')
    css_classes = ['card']
    css_classes << 'card-hover' if hoverable
    css_classes << html_class if html_class.present?
    css_classes.join(' ')
  end

  # Wallet Helper
  def available_credits(wallet)
    return 0 if wallet.nil?
    wallet.total_credits - wallet.locked_credits
  end

  def has_locked_credits?(wallet)
    return false if wallet.nil?
    wallet.locked_credits > 0
  end

  # Package Helper
  def price_per_credit(package)
    return 0 if package.nil? || package.credits.zero?
    package.price_usd / package.credits
  end
end
