from driver import Bot, Fore, Style
import sys
import os

class Menu:
    def __init__(self):
        self.bot = None
        self.choices = {
            "1": self.send_message,
            "2": self.send_with_media,
            "3": self.quit,
        }

    def display(self):
            print("WHATSAPP AUTOMATOR")
            print("""
                1. Send messages
                2. Send messages with media attached
                3. Quit
            """)

    def settings(self):
        print("- Select the file to use for the numbers:")
        csv = self.load_file("csv")
        return csv

    def send_message(self):
        print(Fore.GREEN + "SEND MESSAGES" + Style.RESET_ALL)
        csv = self.settings()
        print("Ready to start sending messages.")
        self.bot = Bot()
        self.bot.csv_numbers = os.path.join("data", csv)
        self.bot.login()

    def send_with_media(self):
        print(Fore.GREEN + "SEND MESSAGES WITH MEDIA" + Style.RESET_ALL)
        input(Fore.YELLOW + "Please COPY the media you want to send with CTRL+C, then press ENTER." + Style.RESET_ALL)
        csv = self.settings()
        print("Ready to start sending messages with media.")
        self.bot = Bot()
        self.bot.csv_numbers = os.path.join("data", csv)
        self.bot._options = True
        self.bot.login()

    def load_file(self, filetype):
        selection = 0
        idx = 1
        files = {}

        for file in os.listdir("data"):
            if file.endswith("." + filetype):
                files[idx] = file
                print(idx, ") ", file)
                idx += 1

        if len(files) == 0:
            raise FileNotFoundError

        while selection not in files.keys():
            selection = int(input("> "))

        return str(files[selection])

    def quit(self):

        sys.exit(0)

    def run(self):
        while True:
            self.display()
            choice = input("Enter an option: ")
            action = self.choices[choice]
            if action:
                action()
                self.quit()
            else:
                print(Fore.RED, choice, " is not a valid choice")
                print(Style.RESET_ALL)

m = Menu()
m.run()
