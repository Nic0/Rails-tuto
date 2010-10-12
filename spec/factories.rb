# By using the symbol ':user', we get Factory Girl
# to symulate the User model.

Factory.define :user do |user|
  user.name                   "Nicolas Foo"
  user.email                  "foo@exemple.com"
  user.password               "foobar"
  user.password_confirmation  "foobar"
end
