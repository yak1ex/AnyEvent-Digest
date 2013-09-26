# NAME

AnyEvent::Digest - A tiny AnyEvent wrapper for Digest::\*

# VERSION

version v0.0.4

# SYNOPSIS

    use AnyEvent;
    use AnyEvent::Digest;
    my $ctx = AnyEvent::Digest->new('Digest::SHA', opts => [1], unit => 65536, backend => 'aio');
    # In addition to that $ctx can be used as Digest::* object, you can call add*_async() methods
    $ctx->addfile_async($file)->cb(sub {
      # Do something like the followings
      my $ctx = shift->recv;
      print $ctx->hexdigest,"\n";
    });
    AE::cv->recv; # Wait

# DESCRIPTION

To calculate message digest for large files may take several seconds.
It may block your program even if you use [AnyEvent](http://search.cpan.org/perldoc?AnyEvent).
This module is a tiny [AnyEvent](http://search.cpan.org/perldoc?AnyEvent) wrapper for `Digest::*` modules,
not to block your program during digest calculation.

Default backend is to use `AnyEvent::idle`.
You can choose [IO::AIO](http://search.cpan.org/perldoc?IO::AIO) backend. You need install [IO::AIO](http://search.cpan.org/perldoc?IO::AIO) and [AnyEvent::AIO](http://search.cpan.org/perldoc?AnyEvent::AIO) for [IO::AIO](http://search.cpan.org/perldoc?IO::AIO) backend.

# METHODS

In addition to the following methods, other methods are forwarded to the base module.
So, you can use an object of this module as if it is an object of base module.
However, `addfile()` calls `recv()` internally so that [AnyEvent](http://search.cpan.org/perldoc?AnyEvent) backend you use SHOULD supprot blocking wait.
If you want to avoid blocking wait, you can use `addfile_base()` instead.

## `new($base, %args)`

This is a constructor method.
`$base` specifies a module name for base digest implementation, which is expected to be one of `Digest::*` modules.
`'require'` is called for the base module, so you don't have to do `'require'` explicitly.

Available keys of `%args` are as follows:

- `opts`

    passed to `$base::new` as `@{$args{opts}}`. It MUST be an array reference.

- `unit`

    specifies an amount of read unit for addfile(). Default to 65536 = 64KiB.

- `backend`

    specifies a backend module to handle asynchronous read. Available backends are `'idle'` and `'aio'`. Default to `'idle'`.

## `add_async(@dat)`

Each item in `@dat` are added by `add($dat)`.
Between the adjacent `add()`, other [AnyEvent](http://search.cpan.org/perldoc?AnyEvent) watchers have chances to run.
It returns a condition variable receiving this object itself.

## `addfile_async($filename)`

## `addfile_async(*handle)`

`add()` is called repeatedly read from `$filename` or `*handle` by the specified unit.
Between the adjacent `add()`, other [AnyEvent](http://search.cpan.org/perldoc?AnyEvent) watchers have chances to run.
It returns a condition variable receiving this object itself.

## `add_bits_async()`

Same as `add_bits()`, except it returns a condition variable receiving this object itself.

__CAUTION:__ Currerntly, other [AnyEvent](http://search.cpan.org/perldoc?AnyEvent) watchers have __NO__ chance to run during this call.

## `addfile()`

This method uses blocking wait + `addfile_async()`.

## `addfile_base()`

Forwarded to `addfile()` in the base module. If you need to avoid blocking wait somewhere, this might be helpful.
However, during the call, other [AnyEvent](http://search.cpan.org/perldoc?AnyEvent) watchers  are blocked.

# SEE ALSO

- [AnyEvent](http://search.cpan.org/perldoc?AnyEvent)
- [AnyEvent::AIO](http://search.cpan.org/perldoc?AnyEvent::AIO)
- [IO::AIO](http://search.cpan.org/perldoc?IO::AIO)
- [Digest](http://search.cpan.org/perldoc?Digest)

# AUTHOR

Yasutaka ATARASHI <yakex@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Yasutaka ATARASHI.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
