create user 'sbtest'@'%' identified by 'kvm';
create database sbtest;
grant all privileges on sbtest.* to 'sbtest'@'%' identified by 'kvm';
set global max_connections=10000;
set global max_user_connections=0;
