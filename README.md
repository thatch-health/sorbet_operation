# sorbet_operation

[![Build Status](https://github.com/thatch-health/sorbet_operation/actions/workflows/main.yml/badge.svg?branch=main)](https://github.com/thatch-health/sorbet_operation/actions?query=branch%3Amain)

sorbet_operation is a minimal operation framework that leverages Sorbet's type system to ensure that operations are well-typed and that their inputs and outputs are well-defined.

An operation is a Ruby class that encapsulates business logic. It is similar to a service class, but whereas service classes often group several related methods, an operation object does one and only one thing.

For example, here is an operation that creates a new user:
```ruby
class CreateUser < SorbetOperation::Base
  ValueType = type_member { { fixed: User } }

  sig { params(user_params: ActiveSupport::Parameters).void }
  def initialize(user_params)
    @user_params = user_params
  end

  protected

  sig { returns(ValueType) }
  def execute
    User.create!(@user_params)
  rescue => e
    raise SorbetOperation::Failure, "User creation failed: #{e.message}"
  end
end
```

In a Rails controller, this operation could be used as follows:
```ruby
class UsersController < ApplicationController
  def create
    result = CreateUser.new(user_params).perform
    if operation.success?
      user = result.unwrap!
      T.reveal_type(user) # `User`
      redirect_to user
    else
      error = result.unwrap_error!
      T.reveal_type(error) # `SorbetOperation::Error`
      render :new, alert: error.message
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password)
  end
end
```

Operations return a result object which indicates whether the operation was successful or not. The result object wraps the return value of the operation if it was successful, or an instance of `SorbetOperation::Error` if it failed.

## Installation

This gem is not yet published to RubyGems.org. For now, you can install it by adding the following to your `Gemfile`:
```ruby
gem "sorbet_operation", github: "thatch-health/sorbet_operation", branch: "main"
```

TODO: Replace `UPDATE_WITH_YOUR_GEM_NAME_PRIOR_TO_RELEASE_TO_RUBYGEMS_ORG` with your gem name right after releasing it to RubyGems.org. Please do not do it earlier due to security reasons. Alternatively, replace this section with instructions to install your gem from git if you don't plan to release to RubyGems.org.

Install the gem and add to the application's Gemfile by executing:

    $ bundle add UPDATE_WITH_YOUR_GEM_NAME_PRIOR_TO_RELEASE_TO_RUBYGEMS_ORG

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install UPDATE_WITH_YOUR_GEM_NAME_PRIOR_TO_RELEASE_TO_RUBYGEMS_ORG

## Usage

An operation is a Ruby class that derives from `SorbetOperation::Base`. `SorbetOperation::Base` is an abstract generic class which requires derived classes to do two things:
1. define the return type using the `ValueType` generic type member
2. define an `#execute` method that returns a `ValueType`

The `#execute` method should be `protected` or `private`, since it is not meant to be invoked directly; rather, operation callers should use the `#perform` public method to actually perform the operation. (Unfortunately, at this time there is no mechanism to enforce that `#execute` is not a public method on child classes, so it's up to the programmer to be vigilant.)

The `#execute` method does not take any arguments. Most operations require one or more input values. Input values should be passed to the `#initialize` constructor method and stored as instance variables, which can then be accessed from the `#execute` body.

There are two possible outcomes for an operation:
1. if `#execute` returns an instance of `ValueType`, then the operation result is a success
2. if `#execute` raises a `SorbetOperation::Error`, then the operation result is a failure

Exceptions that are not an instance of `SorbetOperation::Error` will not be caught by the framework and will be propagated to the operation callsite.

### Using results

Operation callers call `#perform` to perform the operation. `#perform` does not directly the return value of the operation; rather, it returns an instance of `SorbetOperation::Result`, a generic class that wraps the return value or the error depending on whether the operation succeeds or fails.

The `SorbetOperation::Result` class is inspired by Rust's [`Result`](https://doc.rust-lang.org/std/result/enum.Result.html) type, and as a result the API is very similar.

### Operations without a return value

Some operations may be pure side-effects and not need to return anything. When this is the case, you can simply define `ValueType` to be `NilClass`:
```ruby
ValueType = { { fixed: NilClass } }
```

(Alternatively, you could use `Sorbet::Private::Static::Void` instead of `NilClass`. This is arguably better typing, but relying on a type nested under the `Sorbet::Private` namespace is not recommended.)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bin/rake install`. To release a new version, update the version number in `version.rb`, and then run `bin/rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/thatch-health/sorbet_operation.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
