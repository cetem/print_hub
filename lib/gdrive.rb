module GDrive
  extend self

  def upload_spreadsheet(title, array, kwargs={})
    return if array.blank?

    session = GoogleDrive::Session.from_service_account_key(gdrive[:json])

    s = session.spreadsheet_by_title(title)
    s ||= session.create_spreadsheet(title)

    month = kwargs[:month]
    label = kwargs[:label]
    if (month || label).present?
      page_title = label || I18n.t('date.month_names')[month]

      ws = s.worksheet_by_title(page_title)
      unless ws
        size = array.map {|e| e.try(:size).to_i }.max rescue 5
        ws = s.add_worksheet(page_title, array.size + 5, size || 5)
      end
    else
      ws = s.worksheets[0]
    end
    ws.update_cells(1, 1, array)
    ws.save


    puts "https://docs.google.com/spreadsheets/d/#{s.key}/edit#gid=#{ws.gid}"
    puts "https://docs.google.com/spreadsheets/d/#{s.key}/edit#gid=#{ws.gid}"
    puts "https://docs.google.com/spreadsheets/d/#{s.key}/edit#gid=#{ws.gid}"
    puts "https://docs.google.com/spreadsheets/d/#{s.key}/edit#gid=#{ws.gid}"
    puts "https://docs.google.com/spreadsheets/d/#{s.key}/edit#gid=#{ws.gid}"

    sleep 10
    gdrive[:roles].each do |role, users|
      [users].flatten.each do |user|
        perms =  Google::Apis::DriveV3::Permission.new(
          email_address: user, type: 'user', role: role
        )
        session.drive.create_permission(
          s.key, perms, transfer_ownership: (role == 'owner')
        )
      end
    end

    puts "https://docs.google.com/spreadsheets/d/#{s.key}/edit#gid=#{ws.gid}"

  end

  private

  def gdrive
    @_gdrive ||= SECRETS[:gdrive]
  end
end
