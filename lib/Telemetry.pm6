# An attempt at providing an API to nqp::getrusage.

use nqp;

class Telemetry::Period { ... }

class Telemetry {
    has int $!cpu-user;
    has int $!cpu-sys;
    has int $!wallclock;
    has int $!supervisor;
    has int $!general-workers;
    has int $!timer-workers;
    has int $!affinity-workers;

    my num $start = Rakudo::Internals.INITTIME;

    submethod BUILD() {
        my \rusage = nqp::getrusage;
        $!cpu-user = nqp::atpos_i(rusage,nqp::const::RUSAGE_UTIME_SEC) * 1000000
          + nqp::atpos_i(rusage, nqp::const::RUSAGE_UTIME_MSEC);
        $!cpu-sys  = nqp::atpos_i(rusage,nqp::const::RUSAGE_STIME_SEC) * 1000000
          + nqp::atpos_i(rusage, nqp::const::RUSAGE_STIME_MSEC);
        $!wallclock =
          nqp::fromnum_I(1000000 * nqp::sub_n(nqp::time_n,$start),Int);

        my $scheduler := nqp::decont($*SCHEDULER);
        $!supervisor = 1
          if nqp::getattr($scheduler,ThreadPoolScheduler,'$!supervisor');

        if nqp::getattr($scheduler,ThreadPoolScheduler,'$!general-workers')
          -> \workers {
            $!general-workers = nqp::elems(workers);
        }
        if nqp::getattr($scheduler,ThreadPoolScheduler,'$!timer-workers')
          -> \workers {
            $!timer-workers = nqp::elems(workers);
        }
        if nqp::getattr($scheduler,ThreadPoolScheduler,'$!affinity-workers')
          -> \workers {
            $!affinity-workers = nqp::elems(workers);
        }

    }

    proto method cpu() { * }
    multi method cpu(Telemetry:U:) is raw {
        my \rusage = nqp::getrusage;
        nqp::atpos_i(rusage, nqp::const::RUSAGE_UTIME_SEC) * 1000000
          + nqp::atpos_i(rusage, nqp::const::RUSAGE_UTIME_MSEC)
          + nqp::atpos_i(rusage, nqp::const::RUSAGE_STIME_SEC) * 1000000
          + nqp::atpos_i(rusage, nqp::const::RUSAGE_STIME_MSEC)
    }
    multi method cpu(Telemetry:D:) is raw {
        nqp::add_i($!cpu-user,$!cpu-sys)
    }

    proto method cpu-user() { * }
    multi method cpu-user(Telemetry:U:) is raw {
        my \rusage = nqp::getrusage;
        nqp::atpos_i(rusage, nqp::const::RUSAGE_UTIME_SEC) * 1000000
          + nqp::atpos_i(rusage, nqp::const::RUSAGE_UTIME_MSEC)
    }
    multi method cpu-user(Telemetry:D:) is raw { $!cpu-user }

    proto method cpu-sys() { * }
    multi method cpu-sys(Telemetry:U:) is raw {
        my \rusage = nqp::getrusage;
        nqp::atpos_i(rusage, nqp::const::RUSAGE_STIME_SEC) * 1000000
          + nqp::atpos_i(rusage, nqp::const::RUSAGE_STIME_MSEC)
    }
    multi method cpu-sys(Telemetry:D:) is raw { $!cpu-sys }

    proto method wallclock() { * }
    multi method wallclock(Telemetry:U:) is raw {
        nqp::fromnum_I(1000000 * nqp::sub_n(nqp::time_n,$start),Int)
    }
    multi method wallclock(Telemetry:D:) is raw { $!wallclock }

    proto method supervisor() { * }
    multi method supervisor(Telemetry:U:) {
        nqp::istrue(
          nqp::getattr(
            nqp::decont($*SCHEDULER),ThreadPoolScheduler,'$!supervisor'
          )
        )
    }
    multi method supervisor(Telemetry:D:) { $!supervisor }

    proto method general-workers() { * }
    multi method general-workers(Telemetry:U:) {
        nqp::if(
          nqp::istrue((my $workers := nqp::getattr(
            nqp::decont($*SCHEDULER),ThreadPoolScheduler,'$!general-workers'
          ))),
          nqp::elems($workers)
        )
    }
    multi method general-workers(Telemetry:D:) { $!general-workers }

    proto method timer-workers() { * }
    multi method timer-workers(Telemetry:U:) {
        nqp::if(
          nqp::istrue((my $workers := nqp::getattr(
            nqp::decont($*SCHEDULER),ThreadPoolScheduler,'$!timer-workers'
          ))),
          nqp::elems($workers)
        )
    }
    multi method timer-workers(Telemetry:D:) { $!timer-workers }

    proto method affinity-workers() { * }
    multi method affinity-workers(Telemetry:U:) {
        nqp::if(
          nqp::istrue((my $workers := nqp::getattr(
            nqp::decont($*SCHEDULER),ThreadPoolScheduler,'$!affinity-workers'
          ))),
          nqp::elems($workers)
        )
    }
    multi method affinity-workers(Telemetry:D:) { $!affinity-workers }

    multi method Str(Telemetry:D:) {
        $!wallclock ?? "$.cpu / $!wallclock" !! "cpu / wallclock"
    }
    multi method gist(Telemetry:D:) {
        $!wallclock ?? "$.cpu / $!wallclock" !! "cpu / wallclock"
    }
}

class Telemetry::Period is Telemetry {
    multi method new(Telemetry::Period:
      int :$cpu-user,
      int :$cpu-sys,
      int :$wallclock,
      int :$supervisor,
      int :$general-workers,
      int :$timer-workers,
      int :$affinity-workers,
    ) {
        self.new(
          $cpu-user, $cpu-sys, $wallclock,
          $supervisor, $general-workers, $timer-workers, $affinity-workers
        )
    }
    multi method new(Telemetry::Period:
      int $cpu-user,
      int $cpu-sys,
      int $wallclock,
      int $supervisor,
      int $general-workers,
      int $timer-workers,
      int $affinity-workers,
    ) {
        my $period := nqp::create(Telemetry::Period);
        nqp::bindattr_i($period,Telemetry,'$!cpu-user',       $cpu-user);
        nqp::bindattr_i($period,Telemetry,'$!cpu-sys',        $cpu-sys);
        nqp::bindattr_i($period,Telemetry,'$!wallclock',      $wallclock);
        nqp::bindattr_i($period,Telemetry,'$!supervisor',     $supervisor);
        nqp::bindattr_i($period,Telemetry,'$!general-workers',$general-workers);
        nqp::bindattr_i($period,Telemetry,'$!timer-workers',  $timer-workers);
        nqp::bindattr_i($period,Telemetry,'$!affinity-workers',$affinity-workers);
        $period
    }

    multi method perl(Telemetry::Period:D:) {
        "Telemetry::Period.new(:cpu-user({
          nqp::getattr_i(self,Telemetry,'$!cpu-user')
        }), :cpu-sys({
          nqp::getattr_i(self,Telemetry,'$!cpu-sys')
        }), :wallclock({
          nqp::getattr_i(self,Telemetry,'$!wallclock')
        }), :supervisor({
          nqp::getattr_i(self,Telemetry,'$!supervisor')
        }), :general-workers({
          nqp::getattr_i(self,Telemetry,'$!general-workers')
        }), :timer-workers({
          nqp::getattr_i(self,Telemetry,'$!timer-workers')
        }), :affinity-workers({
          nqp::getattr_i(self,Telemetry,'$!affinity-workers')
        }))"
    }

    method cpus() {
        nqp::add_i(
          nqp::getattr_i(self,Telemetry,'$!cpu-user'),
          nqp::getattr_i(self,Telemetry,'$!cpu-sys')
        ) / nqp::getattr_i(self,Telemetry,'$!wallclock')
    }

    my $factor = 100 / Kernel.cpu-cores;
    method utilization() { $factor * self.cpus }
}

multi sub infix:<->(Telemetry:U $a, Telemetry:U $b) is export {
    Telemetry::Period.new(0,0,0)
}
multi sub infix:<->(Telemetry:D $a, Telemetry:U $b) is export { $a     - $b.new }
multi sub infix:<->(Telemetry:U $a, Telemetry:D $b) is export { $a.new - $b     }
multi sub infix:<->(Telemetry:D $a, Telemetry:D $b) is export {
    Telemetry::Period.new(
      nqp::sub_i(
        nqp::getattr_i(nqp::decont($a),Telemetry,'$!cpu-user'),
        nqp::getattr_i(nqp::decont($b),Telemetry,'$!cpu-user')
      ),
      nqp::sub_i(
        nqp::getattr_i(nqp::decont($a),Telemetry,'$!cpu-sys'),
        nqp::getattr_i(nqp::decont($b),Telemetry,'$!cpu-sys')
      ),
      nqp::sub_i(
        nqp::getattr_i(nqp::decont($a),Telemetry,'$!wallclock'),
        nqp::getattr_i(nqp::decont($b),Telemetry,'$!wallclock')
      ),
      nqp::sub_i(
        nqp::getattr_i(nqp::decont($a),Telemetry,'$!supervisor'),
        nqp::getattr_i(nqp::decont($b),Telemetry,'$!supervisor')
      ),
      nqp::sub_i(
        nqp::getattr_i(nqp::decont($a),Telemetry,'$!general-workers'),
        nqp::getattr_i(nqp::decont($b),Telemetry,'$!general-workers')
      ),
      nqp::sub_i(
        nqp::getattr_i(nqp::decont($a),Telemetry,'$!timer-workers'),
        nqp::getattr_i(nqp::decont($b),Telemetry,'$!timer-workers')
      ),
      nqp::sub_i(
        nqp::getattr_i(nqp::decont($a),Telemetry,'$!affinity-workers'),
        nqp::getattr_i(nqp::decont($b),Telemetry,'$!affinity-workers')
      )
    )
}

constant T is export = Telemetry;

my @snaps;
proto sub snap(|) is export { * }
multi sub snap(--> Nil) { @snaps.push(Telemetry.new) }
multi sub snap(@s --> Nil) { @s.push(Telemetry.new) }

my int $snapper-running;
sub snapper($sleep = 0.1 --> Nil) is export {
    unless $snapper-running {
        Thread.start(:app_lifetime, :name<Snapper>, {
            loop { snap; sleep $sleep }
        });
        $snapper-running = 1
    }
}

proto sub periods(|) is export { * }
multi sub periods() {
    my @s = @snaps;
    @snaps = ();
    @s.push(Telemetry.new) if @s == 1;
    (1..^@s).map: { @s[$_] - @s[$_ - 1] }
}
multi sub periods(@s) { (1..^@s).map: { @s[$_] - @s[$_ - 1] } }

END { if @snaps { .say for periods } }

# vim: ft=perl6 expandtab sw=4
