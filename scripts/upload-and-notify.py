#!/usr/bin/env python

import os
import sys
import qiniu.conf
import qiniu.io
import qiniu.rs


def main():

    if len(sys.argv) != 4:
        sys.stderr.write('invalid arguments, should be: key secre')
        return

    qiniu.conf.ACCESS_KEY = sys.argv[1]
    qiniu.conf.SECRET_KEY = sys.argv[2]

    build_file = os.path.abspath(sys.argv[3])

    if not os.path.exists(build_file):
        sys.stderr.write('file not existed, skip upload')
        return

    policy = qiniu.rs.PutPolicy('kernelpanic-im-copymate')
    uptoken = policy.token()
    identifier = os.path.basename(build_file)

    ret, error = qiniu.io.put_file(uptoken, identifier, build_file)
    if error is not None:
        sys.stderr.write('publish failed:%s' % error)
        return

if __name__ == '__main__':
    main()
