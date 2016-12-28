# Handling of crypto keys and special files for Drupal.

# Known Issue: "crypto" value which is supposed to be a variable
# interpolated into the template cryptofile.erb is not passing
# the value from Hiera. Bizzarre issue since this method is the identical
# way that "drupal::website" resource and "php5fpm::pool" resources function.
# Since the files are typically 1-liners, using "$content" to pass the value
# into the file directly instead. -SL 5-July-2016

define drupal::cryptofile(
  $ensure       = file,
  $path,
  $owner        = '0',
  $group        = 'www-data',
  $mode         = '0640',
  $content      = template('drupal/cryptofile.erb'),
  $crpyto_value = undef,
){

  file {"${title}":
    ensure    => "${ensure}",
    path      => "${path}",
    owner     => "${owner}",
    group     => "${group}",
    mode      => "${mode}",
    content   => "${content}",
  }
}
