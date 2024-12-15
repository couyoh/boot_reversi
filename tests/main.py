import sys
import asyncio
import subprocess
import logging
import atexit

class Tester:
    def __init__(self, asmfile, expect):
        self.asmfile = asmfile
        self.expect = expect
        self.p = None
        self.processing = None
        self.buf = ""

        atexit.register(self.clean)

    async def read_stdout(self, stdout):
        while True:
            if self.processing:
                try:
                    buf = await asyncio.wait_for(stdout.readline(), timeout=1)
                    self.buf += buf.decode("utf-8")
                except TimeoutError:
                    inkey, expect = self.processing
                    if expect in self.buf:
                        logging.info(f"OK: {inkey}")
                        self.processing = None
                        self.buf = ""
                    else:
                        logging.warning("Expected to:")
                        logging.warning(expect)
                        logging.warning("Actual:")
                        logging.warning(self.buf)
                        sys.exit(1)
            await asyncio.sleep(0.1)

    async def write_stdin(self, stdin):
        for i in self.expect:
            instr = i[0]
            logging.info(f'input: { instr }')
            buf = instr.encode()

            stdin.write(buf)
            await stdin.drain()
            self.processing = i
            while self.processing is not None:
                await asyncio.sleep(0.1)

    def clean(self):
        if self.p:
            logging.info(f"{self.p.pid} will be killed.")
            self.p.kill()

    async def clear(self):
        try:
            await asyncio.wait_for(self.p.stdout.read(), timeout=1)
        except TimeoutError:
            pass

    async def run(self):
        self.p = await asyncio.create_subprocess_exec("qemu-system-i386", "-nographic", self.asmfile,
                                                      stdin=subprocess.PIPE,
                                                      stdout=subprocess.PIPE,
                                                      stderr=subprocess.PIPE)
        await self.clear()
        logging.info(f"PID: {self.p.pid}")

        async with asyncio.TaskGroup() as tg:
            tg.create_task(self.read_stdout(self.p.stdout))
            tg.create_task(self.write_stdin(self.p.stdin))

async def main():
    expect = [
        [
            "f4", (
                "........1\r\n"
                "........2\r\n"
                "........3\r\n"
                "...OOO..4\r\n"
                "...XO...5\r\n"
                "........6\r\n"
                "........7\r\n"
                "........8\r\n"
            )
        ],
        [
            "f5", (
                "........1\r\n"
                "........2\r\n"
                "........3\r\n"
                "...OOO..4\r\n"
                "...XXX..5\r\n"
                "........6\r\n"
                "........7\r\n"
                "........8\r\n"
            )
        ],
        [
            "d6", (
                "........1\r\n"
                "........2\r\n"
                "........3\r\n"
                "...OOO..4\r\n"
                "...OOX..5\r\n"
                "...O....6\r\n"
                "........7\r\n"
                "........8\r\n"
            )
        ],
        [
            "f3", (
                "........\r\n"
                "........\r\n"
                ".....X..\r\n"
                "...OOX..\r\n"
                "...OOX..\r\n"
                "...O....\r\n"
                "........\r\n"
                "........\r\n"
            )
        ],
        [
            "g2", (
                "........\r\n"
                "......O.\r\n"
                ".....O..\r\n"
                "...OOX..\r\n"
                "...OOX..\r\n"
                "...O....\r\n"
                "........\r\n"
                "........\r\n"
            )
        ],
        [
            "f2", (
                "........\r\n"
                ".....XO.\r\n"
                ".....X..\r\n"
                "...OOX..\r\n"
                "...OOX..\r\n"
                "...O....\r\n"
                "........\r\n"
                "........\r\n"
            )
        ],
        [
            "e2", (
                "........\r\n"
                "....OOO.\r\n"
                ".....X..\r\n"
                "...OOX..\r\n"
                "...OOX..\r\n"
                "...O....\r\n"
                "........\r\n"
                "........\r\n"
            )
        ],
        [
            "c7", (
                "........\r\n"
                "....OOO.\r\n"
                ".....X..\r\n"
                "...OOX..\r\n"
                "...OXX..\r\n"
                "...X....\r\n"
                "..X.....\r\n"
                "........\r\n"
            )
        ],
        [
            "g4", (
                "........\r\n"
                "....OOO.\r\n"
                ".....O..\r\n"
                "...OOOO.\r\n"
                "...OXX..\r\n"
                "...X....\r\n"
                "..X.....\r\n"
                "........\r\n"
            )
        ],
        [
            "d3", (
                "........\r\n"
                "....OOO.\r\n"
                "...X.O..\r\n"
                "...XXOO.\r\n"
                "...XXX..\r\n"
                "...X....\r\n"
                "..X.....\r\n"
                "........\r\n"
            )
        ],
        [
            "c6", (
                "........\r\n"
                "....OOO.\r\n"
                "...X.O..\r\n"
                "...XOOO.\r\n"
                "...OXX..\r\n"
                "..OX....\r\n"
                "..X.....\r\n"
                "........\r\n"
            )
        ],
        [
            "h4", (
                "........\r\n"
                "....OOO.\r\n"
                "...X.O..\r\n"
                "...XXXXX\r\n"
                "...OXX..\r\n"
                "..OX....\r\n"
                "..X.....\r\n"
                "........\r\n"
            )
        ]
    ]
    tester = Tester(sys.argv[1], expect)
    await tester.run()
    return 0

logging.basicConfig(level=logging.DEBUG)
asyncio.run(main())
