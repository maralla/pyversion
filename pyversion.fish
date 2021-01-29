function pyversion -d 'Python version installer'
    set -l cmd "__pyversion__$argv[1]"
    set -e argv[1]
    eval $cmd $argv
end

function __pyversion__versions
    set -l tmpfile (mktemp /tmp/pyversion-XXXXXX)

    curl -sS "https://www.python.org/ftp/python/" -o $tmpfile
    sed -E -e 's|.*>([0-9]+\.[0-9]+(\.[0-9]+)?)/<.*|\1|;/[a-w]/d' $tmpfile | sort

    rm "$tmpfile"
end

function __pyversion__install -a pyv
    set -l pydir /usr/local/var/pyversion

    if [ ! -d "$pydir" ]
        mkdir $pydir
    end

    if [ -d "$pydir/$pyv" ]
        echo "python v$pyv already installed in $pydir/$pyv"
        return
    end

    set -l dir (mktemp -d /tmp/pyversion-install-XXXXXX)

    function _cleanup --on-event fish_postexec -V dir
        functions -e _cleanup
        rm -rf $dir
    end

    function _sigint --on-signal SIGINT
        functions -e _sigint
        if [ -d "$pydir/$pyv" ]
            rm -rf $pydir/$pyv
        end
    end

    curl https://www.python.org/ftp/python/$pyv/Python-$pyv.tar.xz --output $dir/$pyv.tar.xz; or return
    tar -xf $dir/$pyv.tar.xz -C $dir; or return

    echo building...

    sh -c "cd $dir/Python-$pyv && ./configure --prefix=$pydir/$pyv -q"; or return

    make -C $dir/Python-$pyv -s -j2; or return

    mkdir $pydir/$pyv

    if not make -C $dir/Python-$pyv -s install
        rm -rf $pydir/$pyv
        return
    end

    echo "python v$pyv installed to $pydir/$pyv"
end
