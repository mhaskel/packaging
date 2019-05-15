plan prime_gpg {
  $passphrase = prime_gpg::prompt("Passphrase for GPG key", true)
  run_task('prime_gpg::prime', 'weth.delivery.puppetlabs.net', 'directory' => '/home/morgan/enterprise-dist', 'use_rvm' => true, 'gpg2' => false, 'passphrase' => "${passphrase.unwrap()}")
}
