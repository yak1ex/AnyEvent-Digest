# NAME

AnyEvent::Digest - A tiny AnyEvent wrapper for Digest::\*

# VERSION

version v0.0.0

# SYNOPSIS

    use AnyEvent::Digest;
    use Digest::SHA;
    my $ctx = AnyEvent::Digest->new('SHA', opts => [1], unit => 65536, backend => 'IO::AIO');
    # In addition that $ctx can be used as Digest::* object, you can call add*_async()
    $ctx->addfile_async($file)->recv(sub {
      # Do something like the followings
      my $ctx = $_[0]->recv;
      print $ctx->hexdigest;
    });

# DESCRIPTION

To calculate message digest for large files may take several seconds.
It may block your program even if you use [AnyEvent](http://search.cpan.org/perldoc?AnyEvent).
This module is a tiny AnyEvent wrapper for Digest::\* modules,
not to block your program during digest calculation.

# METHODS

In addition to the following methods, other methods are forwarded to the base module.

## `new($base, %args)`

This is a constructor method.
`$base` specifies a module name for base implementation, which is expected to be one of `Digest::*` modules.
Available keys of `%args` are as follows:

- `opts`

    passed to `$base::new` as `@{$args{opts}}`. It must be an array reference.

- `unit`

    specifies an amount of one time read for addfile(). Defaults to 65536 = 64KiB.

- `backend`

    specifies a backend module to handle asynchronous read. Currently, only `'idle'` is available and default.

## `add_async(@dat)`

Each item in `@dat` are added by `add($dat)`.
Between the adjacent `add()`, other AnyEvent watchers have chances to run.
It returns a condition variable receiving this object itself.

## `addfile_async($filename)`

## `addfile_async(*handle)`

`add()` is called repeatedly read from `$filename` or `*handle` by the specified unit.
Between the adjacent `add()`, other AnyEvent watchers have chances to run.
It returns a condition variable receiving this object itself.

## `add_bits_async()`

Same as `add_bits()`, except it returns a condition variable receiving this object itself.

## `addfile()`

This method uses blocking wait + `addfile_async()`.

## `addfile_base()`

Forwarded to `addfile()` in the base module.

# AUTHOR

Yasutaka ATARASHI <yakex@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Yasutaka ATARASHI.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
