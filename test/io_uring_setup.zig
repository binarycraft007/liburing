/// SPDX-License-Identifier: MIT
///
/// io_uring_setup.zig
///
/// Description: Unit tests for the io_uring_setup system call.
///
const std = @import("std");
const os = std.os;
const mem = std.mem;
const c = @cImport({
    @cInclude("liburing.h");
});
const testing = std.testing;
const linux = os.linux;

pub fn uringSetup(entries: u32, p: [*c]c.struct_io_uring_params) !void {
    var res = c.io_uring_setup(entries, p);
    switch (linux.getErrno(@intCast(usize, res))) {
        .SUCCESS => {},
        .FAULT => return error.ParamsOutsideAccessibleAddressSpace,
        // The resv array contains non-zero data, p.flags contains an unsupported flag,
        // entries out of bounds, IORING_SETUP_SQ_AFF was specified without IORING_SETUP_SQPOLL,
        // or IORING_SETUP_CQSIZE was specified but linux.io_uring_params.cq_entries was invalid:
        .INVAL => return error.ArgumentsInvalid,
        .MFILE => return error.ProcessFdQuotaExceeded,
        .NFILE => return error.SystemFdQuotaExceeded,
        .NOMEM => return error.SystemResources,
        // IORING_SETUP_SQPOLL was specified but effective user ID lacks sufficient privileges,
        // or a container seccomp policy prohibits io_uring syscalls:
        .PERM => return error.PermissionDenied,
        .NOSYS => return error.SystemOutdated,
        else => |errno| return os.unexpectedErrno(errno),
    }
}

test "io_uring_setup" {
    var params = mem.zeroInit(c.struct_io_uring_params, .{
        .flags = 0,
        .sq_thread_idle = 1000,
    });
    try uringSetup(32, &params);
}
//int main(int argc, char **argv)
//{
//	int fd;
//	unsigned int status = 0;
//	struct io_uring_params p;
//
//	if (argc > 1)
//		return T_EXIT_SKIP;
//
//	memset(&p, 0, sizeof(p));
//	status |= try_io_uring_setup(0, &p, -EINVAL);
//	status |= try_io_uring_setup(1, NULL, -EFAULT);
//
//	/* resv array is non-zero */
//	memset(&p, 0, sizeof(p));
//	p.resv[0] = p.resv[1] = p.resv[2] = 1;
//	status |= try_io_uring_setup(1, &p, -EINVAL);
//
//	/* invalid flags */
//	memset(&p, 0, sizeof(p));
//	p.flags = ~0U;
//	status |= try_io_uring_setup(1, &p, -EINVAL);
//
//	/* IORING_SETUP_SQ_AFF set but not IORING_SETUP_SQPOLL */
//	memset(&p, 0, sizeof(p));
//	p.flags = IORING_SETUP_SQ_AFF;
//	status |= try_io_uring_setup(1, &p, -EINVAL);
//
//	/* attempt to bind to invalid cpu */
//	memset(&p, 0, sizeof(p));
//	p.flags = IORING_SETUP_SQPOLL | IORING_SETUP_SQ_AFF;
//	p.sq_thread_cpu = get_nprocs_conf();
//	status |= try_io_uring_setup(1, &p, -EINVAL);
//
//	/* I think we can limit a process to a set of cpus.  I assume
//	 * we shouldn't be able to setup a kernel thread outside of that.
//	 * try to do that. (task->cpus_allowed) */
//
//	/* read/write on io_uring_fd */
//	memset(&p, 0, sizeof(p));
//	fd = io_uring_setup(1, &p);
//	if (fd < 0) {
//		fprintf(stderr, "io_uring_setup failed with %d, expected success\n",
//		       -fd);
//		status = 1;
//	} else {
//		char buf[4096];
//		int ret;
//		ret = read(fd, buf, 4096);
//		if (ret >= 0) {
//			fprintf(stderr, "read from io_uring fd succeeded.  expected fail\n");
//			status = 1;
//		}
//	}
//
//	if (!status)
//		return T_EXIT_PASS;
//
//	fprintf(stderr, "FAIL\n");
//	return T_EXIT_FAIL;
//}
