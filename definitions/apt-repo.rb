define :apt_repo,
    :key_package => nil,
    :key_id => nil,
    :key_url => nil,
    :keyserver => "keys.gnupg.net",
    :url => nil,
    :distribution => nil,
    :components => "main",
    :description => nil do

  unless params[:key_package] or params[:key_id]
    raise "Cannot find key_package or key_id"
  end

  unless params[:url]
    raise "Cannot find url"
  end

  components = params[:components]
  components = components.join(' ') if components.kind_of?(Array)
  distribution = params[:distribution] || node[:lsb][:codename]
  description = params[:description] || params[:name].capitalize

  if params[:key_id]
    key_id = params[:key_id]
    key_url = params[:key_url]
    keyserver = params[:keyserver]
    key_installed = "apt-key list | grep #{key_id}"
    if key_url
      execute "apt-key adv --fetch #{key_url}" do
        not_if key_installed
      end
    elsif keyserver
      execute "apt-key adv --keyserver #{keyserver} --recv-keys #{key_id}" do
        not_if key_installed
      end
    end
  end

  directory "/etc/apt/sources.list.d"
  file "repo.list" do
    path "/etc/apt/sources.list.d/#{params[:name]}.list"
    entry = "#{params[:url]} #{distribution} #{components} ##{description}"
    content <<EOF
deb     #{entry}
deb-src #{entry}
EOF
    mode "0644"
  end

  execute "aptitude update" do
    action :nothing
    subscribes :run, resources(:file => "repo.list"), :immediately
  end

  if params[:key_package]
    package params[:key_package] do
      options "--allow-unauthenticated" unless key_installed
    end
  end
end
