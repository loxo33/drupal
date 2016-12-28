# Pre-requisites for Drupal sites.
# TODO:
# Fix profiles::website::prereq requirement; we just need the docroot. Probably better as a File virtual resource. 
# Add more options Drupal 6 support? 
# inherit params with defaults :
# fastcgi server and ports should be variables, not hard coded to 127.0.0.1:9000.
# if memcache is used, php-memcached should be included in php packages. 
define drupal::website(
  $sitename = undef,
  $drupal_db_name = undef,
  $drupal_user = undef,
  $drupal_pass = undef,
  $drupal_db_host = undef,
  $drupal_version = "7",
  $drupal_cache_method = undef,
  $drupal_cache_server = undef,
){
  require profiles::websites::prereq
  include drupal::packages

  nginx::resource::vhost { "${sitename}":
    server_name          => ["${sitename}"],
    www_root             => "/var/www/${sitename}/current",
    index_files          => ['index.php'],
    use_default_location => false,
    vhost_cfg_prepend           => {
        'fastcgi_keep_conn'     => 'on',
    },
    raw_append		=> [
     "## Deny illegal Host headers
      if (\$host !~* ^(${sitename}|aws-${sitename})$ ) {
        return 444;
      }"
    ],
  }
  nginx::resource::location { "${sitename}_root":
    ensure                      => 'present',
    location                    => '/',
    vhost                       => "${sitename}",
    www_root                    => "/var/www/${sitename}/current",
    index_files                 => [],
    try_files                   => ['$uri @drupal'],
    raw_append 			=> [
        'include conf.d/advagg.confd;',
    ],
  }
  nginx::resource::location { "${sitename}_php":
    ensure                      => 'present',
    location                    => '~ \.php$',
    vhost                       => "${sitename}",
    fastcgi			=> '127.0.0.1:9000',
    fastcgi_params		=> '/etc/nginx/conf.d/fastcgi_drupal.conf',
  }
  nginx::resource::location { "${sitename}_styles":
    ensure                      => 'present',
    location                    => '~* /files/styles/',
    vhost                       => "${sitename}",
    www_root                    => "/var/www/${sitename}/current",
    index_files                 => [],
    try_files                   => ['$uri @drupal'],
    raw_append => [
        #include conf.d/hotlinking_protection.conf;
        'access_log off;',
        'expires 30d;',
        ],
  }
  nginx::resource::location { "${sitename}_dot":
    ensure                      => 'present',
    location                    => '~ (^|/)\.',
    vhost                       => "${sitename}",
    www_root                    => "/var/www/${sitename}/current",
    index_files                 => [],
    raw_append => [
        'return 403;'],
  }
  nginx::resource::location { "${sitename}_static":
    ensure                      => 'present',
    location                    => '~* ^.+\.(?:css|cur|js|jpe?g|gif|htc|ico|png|html|xml|otf|ttf|eot|woff|svg)$',
    vhost                       => "${sitename}",
    www_root                    => "/var/www/${sitename}/current",
    index_files                 => [],
    raw_append => [
      'access_log off;',
      'expires 30d;',
      'etag on;',
      'gzip_static on;',
      'tcp_nodelay off;',
      'add_header Pragma public;',
      'add_header Cache-Control "public, must-revalidate, proxy-revalidate";',
    ],
  }
  nginx::resource::location { "${sitename}_index":
    ensure                      => 'present',
    location                    => '= /index.php',
    vhost                       => "${sitename}",
    www_root                    => "/var/www/${sitename}/current",
    index_files                 => [],
    raw_append => [
          'internal;',
          'include conf.d/fastcgi_drupal.conf;',
          'fastcgi_pass 127.0.0.1:9000;',
    ],
  }
  nginx::resource::location { "${sitename}_favicon":
    ensure                      => 'present',
    location                    => '= /favicon.ico',
    vhost                       => "${sitename}",
    www_root                    => "/var/www/${sitename}/current",
    index_files                 => [],
    raw_append => [
        'empty_gif;',
        'expires 30d;',
        'log_not_found off;',
        'access_log off;',
    ],
  }
  nginx::resource::location { "${sitename}_robots":
    ensure                      => 'present',
    location                    => '= /robots.txt',
    vhost                       => "${sitename}",
    www_root                    => "/var/www/${sitename}/current",
    index_files                 => [],
    raw_append => [
        'log_not_found off;',
        'access_log off;',
    ],
  }  
  nginx::resource::location { "${sitename}_anti_php":
    ensure                      => 'present',
    location                    => '~ \..*/.*\.php$',
    vhost                       => "${sitename}",
    www_root                    => "/var/www/${sitename}/current",
    index_files                 => [],
    raw_append => [
        'return 403;'],
    }

  nginx::resource::location { "${sitename}_private":
    ensure                      => 'present',
    location                    => '~ ^/sites/.*/private/',
    vhost                       => "${sitename}",
    www_root                    => "/var/www/${sitename}/current",
    index_files                 => [],
    raw_append => [
        'return 403;'],
  }
  nginx::resource::location { "${sitename}_sitemap":
    ensure                      => 'present',
    location                    => '= /sitemap.xml',
    vhost                       => "${sitename}",
    www_root                    => "/var/www/${sitename}/current",
    index_files                 => [],
    try_files                   => ['$uri @drupal-no-args'],
  }
  nginx::resource::location { "${sitename}_atdrupal":
    location                    => '@drupal',
    vhost                       => "${sitename}",
    fastcgi			=> "127.0.0.1:9000",
    fastcgi_params		=> '/etc/nginx/conf.d/fastcgi_drupal.conf',
  }
  nginx::resource::location { "${sitename}_atdrupal_noargs":
    location                    => '@drupal-no-args',
    vhost                       => "${sitename}",
    fastcgi			=> "127.0.0.1:9000",
    fastcgi_params		=> '/etc/nginx/conf.d/fastcgi_no_args_drupal.conf',
  }
  nginx::resource::location {"${sitename}_files":
    ensure			=> 'present',
    location			=> '/files',
    vhost			=> "${sitename}",
    location_alias		=> "/var/www/${sitename}/files",
  }

  file { "/var/www/${sitename}":
    ensure  => 'directory',
    owner   => hiera("websites::deployment::user"),
    group   => 'www-data',
    mode    => '0640',
  }
  file { "/var/www/${sitename}/releases":
    ensure  => 'directory',
    owner   => hiera("websites::deployment::user"),
    group   => 'www-data',
    mode    => '0640',
    require => File["/var/www/${sitename}"],
  }
  file { "/var/www/${sitename}/private":
    ensure  => 'directory',
    owner   => hiera("websites::deployment::user"),
    group   => 'www-data',
    mode    => '0640',
    require => File["/var/www/${sitename}"],
  }
  file { "/var/www/${sitename}/files":
    ensure  => 'directory',
    owner   => '0',
    group   => 'www-data',
    mode    => '0660',
    require => File["/var/www/${sitename}"],
  }

  ## Create the local.settings.php for localized Drupal configurations. ##
  concat { "${sitename}_local.settings.php":
    ensure  => present,
    path    => "/var/www/${sitename}/private/local.settings.php",
    owner   => "www-data",
    group   => "www-data",
    mode    => '0440',
  }
  concat::fragment { "${sitename}_local_settings_header":
    target  => "${sitename}_local.settings.php",
    content => template("drupal/d${drupal_version}_header.erb"),
    order   => '01',
  }
  concat::fragment { "${sitename}_local_settings_db_connection":
    target  => "${sitename}_local.settings.php",
    content => template("drupal/d${drupal_version}_db_connection.erb"),
    order   => '10',
  }
# If caching is enabled, we set the proper caching template 
  if ($drupal_cache_method != undef) {
    $caching_config = $drupal_cache_method ? {
      "memcached" => "d${drupal_version}_memcached.erb",
      "redis"     => "d${drupal_version}_redis.erb",
    }
    concat::fragment { "${sitename}_local_settings_caching":
      target  => "${sitename}_local.settings.php",
      content => template("drupal/$caching_config"),
      order   => '15',
    }
    package { 'php5-memcached':
      ensure     => installed,
    }
  }
}
