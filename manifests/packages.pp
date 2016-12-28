# Install required Drupal packages
class drupal::packages {
# Upstream package mantainers like aptitude use outdate drush binaries, so we use Composer to install. 
# This class requires 'willdurand-composer'.
# Binaries are linked into /usr/local/bin to fix $PATH for these 3rd-party applications.

  file {'/opt/composer':
    ensure       => 'directory',
  }

  file {'/usr/local/bin/composer':
    ensure       => 'link',
    target       => '/opt/composer/composer',
    require      => Class['composer'],
  } 

  class { 'composer':
    command_name => 'composer',
    target_dir   => '/opt/composer',
    require      => File['/opt/composer'],
  }

  exec {'composer_get_drush':
    command      => '/usr/local/bin/composer global require drush/drush:7.*',
    environment  => ['PATH=/usr/bin:/usr/local/bin','COMPOSER_HOME=/opt/composer/vendor/bin'],
    creates      => '/opt/composer/vendor/bin/vendor/drush/drush/drush',
    require      => File['/usr/local/bin/composer'],
  }

  file {'/usr/local/bin/drush':
    ensure       => 'link',
    target       => '/opt/composer/vendor/bin/vendor/drush/drush/drush',
  }

# If caching is enabled, we set the proper caching template
  if ($drupal_cache_method == 'memcached') {
    package { 'php5-memcached':
      ensure     => installed,
    }
  }
}
