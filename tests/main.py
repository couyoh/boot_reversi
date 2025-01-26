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
                "........1\r\n"
                "........2\r\n"
                ".....X..3\r\n"
                "...OOX..4\r\n"
                "...OOX..5\r\n"
                "...O....6\r\n"
                "........7\r\n"
                "........8\r\n"
            )
        ],
        # [
        #     "g6", (
        #         "........1\r\n"
        #         "........2\r\n"
        #         ".....X..3\r\n"
        #         "...OOX..4\r\n"
        #         "...OOO..5\r\n"
        #         "...O..O.6\r\n"
        #         "........7\r\n"
        #         "........8\r\n"
        #     )
        # ],
        # [
        #     "c4", (
        #         "........1\r\n"
        #         "........2\r\n"
        #         ".....X..3\r\n"
        #         "..XXXX..4\r\n"
        #         "...OOO..5\r\n"
        #         "...O..O.6\r\n"
        #         "........7\r\n"
        #         "........8\r\n"
        #     )
        # ],
        # [
        #     "c3", (
        #         "........1\r\n"
        #         "........2\r\n"
        #         "..O..X..3\r\n"
        #         "..XOXX..4\r\n"
        #         "...OOO..5\r\n"
        #         "...O..O.6\r\n"
        #         "........7\r\n"
        #         "........8\r\n"
        #     )
        # ],
        # [
        #     "e6", (
        #         "........1\r\n"
        #         "........2\r\n"
        #         "..O..X..3\r\n"
        #         "..XOXX..4\r\n"
        #         "...XXO..5\r\n"
        #         "...OX.O.6\r\n"
        #         "........7\r\n"
        #         "........8\r\n"
        #     )
        # ],
        # [
        #     "g3", (
        #         "........1\r\n"
        #         "........2\r\n"
        #         "..O..XO.3\r\n"
        #         "..XOXO..4\r\n"
        #         "...XOO..5\r\n"
        #         "...OX.O.6\r\n"
        #         "........7\r\n"
        #         "........8\r\n"
        #     )
        # ],
        [
            "g2", (
                "........1\r\n"
                "......O.2\r\n"
                ".....O..3\r\n"
                "...OOX..4\r\n"
                "...OOX..5\r\n"
                "...O....6\r\n"
                "........7\r\n"
                "........8\r\n"
            )
        ],
        [
            "f2", (
                "........1\r\n"
                ".....XO.2\r\n"
                ".....X..3\r\n"
                "...OOX..4\r\n"
                "...OOX..5\r\n"
                "...O....6\r\n"
                "........7\r\n"
                "........8\r\n"
            )
        ],
        [
            "e2", (
                "........1\r\n"
                "....OOO.2\r\n"
                ".....X..3\r\n"
                "...OOX..4\r\n"
                "...OOX..5\r\n"
                "...O....6\r\n"
                "........7\r\n"
                "........8\r\n"
            )
        ],
        [
            "c7", (
                "........1\r\n"
                "....OOO.2\r\n"
                ".....X..3\r\n"
                "...OOX..4\r\n"
                "...OXX..5\r\n"
                "...X....6\r\n"
                "..X.....7\r\n"
                "........8\r\n"
            )
        ],
        [
            "g4", (
                "........1\r\n"
                "....OOO.2\r\n"
                ".....O..3\r\n"
                "...OOOO.4\r\n"
                "...OXX..5\r\n"
                "...X....6\r\n"
                "..X.....7\r\n"
                "........8\r\n"
            )
        ],
        [
            "d3", (
                "........1\r\n"
                "....OOO.2\r\n"
                "...X.O..3\r\n"
                "...XXOO.4\r\n"
                "...XXX..5\r\n"
                "...X....6\r\n"
                "..X.....7\r\n"
                "........8\r\n"
            )
        ],
        [
            "c6", (
                "........1\r\n"
                "....OOO.2\r\n"
                "...X.O..3\r\n"
                "...XOOO.4\r\n"
                "...OXX..5\r\n"
                "..OX....6\r\n"
                "..X.....7\r\n"
                "........8\r\n"
            )
        ],
        [
            "h4", (
                "........1\r\n"
                "....OOO.2\r\n"
                "...X.O..3\r\n"
                "...XXXXX4\r\n"
                "...OXX..5\r\n"
                "..OX....6\r\n"
                "..X.....7\r\n"
                "........8\r\n"
            )
        ]
    ]
    tester = Tester(sys.argv[1], expect)
    await tester.run()
    return 0

logging.basicConfig(level=logging.DEBUG)
asyncio.run(main())
