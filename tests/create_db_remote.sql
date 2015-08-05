GRANT USAGE ON *.* TO 'sbtest'@'localhost';
drop user 'sbtest'@'localhost';
create user 'sbtest'@'localhost' identified by 'kvm';
drop database if exists sbtest;
create database sbtest;
grant all privileges on sbtest.* to 'sbtest'@'remote' identified by 'kvm';
set global max_connections=500;
