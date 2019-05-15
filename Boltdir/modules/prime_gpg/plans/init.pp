plan prime_gpg {
  $passphrase = prime_gpg::prompt('banner' => "Passphrase for GPG key", 'sensitive' => true)
  run_task('prime_gpg::prime', 'weth.delivery.puppetlabs.net', 'directory' => '/tmp', 'use_rvm' => 'true', 'gpg2' => 'false', 'passphrase' => "${passphrase.unwrap()}")
}
