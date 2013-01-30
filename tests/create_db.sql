create user 'sbtest'@'localhost' identified by 'kvm';
create database sbtest;
grant all privileges on sbtest.* to 'sbtest'@'localhost' identified by 'kvm';
