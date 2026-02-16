
import csv
import os.path
import random
import time
from time import sleep
from colorama import Fore, Style
from selenium import webdriver
from selenium.common import TimeoutException
from selenium.webdriver import Keys
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service as ChromeService
from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait
from webdriver_manager.chrome import ChromeDriverManager
# Define a timeout for waiting for elements to load\

timeout = 30

class Bot:
    """
    Bot class that automates WhatsApp Web interactions using a Chrome driver.
    """

    def __init__(self):
        # Configure Chrome options
        options = Options()

        user_data_dir = os.path.join(os.getcwd(), "Whatsapp-Automator-main")
        options.add_argument(f"--user-data-dir={user_data_dir}")

        # Initialize the undetected Chrome driver
        self.driver = webdriver.Chrome(
            service=ChromeService(ChromeDriverManager().install()), 
            options=options
        )
        self._csv_numbers = None
        self._start_time = None
        self._loaction = -1
        self._start = None

    def click_button(self, css_selector):
        """
        Clicks the specified button by its CSS selector.
        """
        button = WebDriverWait(self.driver, timeout).until(
            EC.element_to_be_clickable((By.CSS_SELECTOR, css_selector))
        )
        sleep(0.2)
        button.click()

    def login(self):
        """
        Logs in to WhatsApp Web by navigating to the login page.
        Waits indefinitely until the QR code is scanned and/or clickable element appears.
        """
        logged_in = False  # Track login status

        while not logged_in:  # Loop only until login is successful
            try:
                self.driver.get('https://web.whatsapp.com')
                print("Attempting to load WhatsApp Web...")

                # Wait for the clickable element, success_message and error_message are shown only once
                logged_in = self.wait_for_element_to_be_clickable(
                "//div[@contenteditable='true' and @data-tab='3']",
                success_message="Logged in successfully!",
                error_message="Waiting for QR code to be scanned..."
                )

                if logged_in:
                    break  # Exit the loop on successful login

            except Exception as e:
                print(f"Error during login: {e}")
                print("Retrying login...")

            # Wait before retrying to prevent an infinite loop from flooding the system
            time.sleep(25)

        # Wait for whatsapp to load messages
        time.sleep(5)
        # Record the start time for logs once the login is successful
        self._start_time = time.strftime("%d-%m-%Y_%H%M%S", time.localtime())
        self.send_messages_to_all_contacts()
    
    def log_result(self, number, error):
        """
        Logs the result of each message send attempt.
        """
        assert self._start_time is not None
        log_path = "logs/" + self._start_time + ("_notsent.txt" if error else "_sent.txt")

        with open(log_path, "a") as logfile:
            logfile.write(number.strip() + "\n")

    def paste_media(self):
        """
        Pastes selected media using CTRL+V.
        """
        message_box_selector = "#main > footer > div.x1n2onr6.xhtitgo.x9f619.x78zum5.x1q0g3np.xuk3077.x193iq5w.x122xwht.x1bmpntp.xs9asl8.x1swvt13.x1pi30zi.xnpuxes.copyable-area > div > span > div > div._ak1r > div.x9f619.x12lumcd.x1qrby5j.xeuugli.xisnujt.x6prxxf.x1fcty0u.x1fc57z9.xe7vic5.x1716072.xgde2yp.x89wmna.xbjl0o0.x13fuv20.xu3j5b3.x1q0q8m5.x26u7qi.x178xt8z.xm81vs4.xso031l.xy80clv.x1lq5wgf.xgqcy7u.x30kzoy.x9jhf4c.x1a2a7pz.x13w7htt.x78zum5.x96k8nx.xdvlbce.x1ye3gou.xn6708d.x1ok221b.xu06os2.x1i64zmx.x1emribx > div > div.x1hx0egp.x6ikm8r.x1odjw0f.x1k6rcq7.x6prxxf > p"
        message_box = WebDriverWait(self.driver, timeout).until(
            EC.element_to_be_clickable((By.CSS_SELECTOR, message_box_selector))
        )
        message_box.send_keys(Keys.CONTROL, 'v')

    def quit_driver(self):
        """
        Closes the WebDriver session and quits the browser.
        """
        if self.driver:
            self.driver.quit()
            print(Fore.YELLOW, "Driver closed successfully.", Style.RESET_ALL)

    def open_chat_with_contact(self, contact_number):
        """
        Opens the chat with the given contact name using the search function.
        """
        # Click on the search box to start searching for the contact
        add_contact_selector = "#app > div > div > div.x78zum5.xdt5ytf.x5yr21d > div > div._aigw._as6h.x9f619.x1n2onr6.x5yr21d.x17dzmu4.x1i1dayz.x2ipvbc.xjdofhw.x78zum5.xdt5ytf.x12xzxwr.x1plvlek.xryxfnj.x570efc.x18dvir5.xxljpkc.xwfak60.x18pi947 > header > header > div > span > div > div:nth-child(1) > span > button > div > div > div:nth-child(1) > span"
        add_sign = WebDriverWait(self.driver, timeout).until(
            EC.element_to_be_clickable((By.CSS_SELECTOR, add_contact_selector))
        )
        sleep(0.1)
        add_sign.click()
        search_box_selector = "#app > div > div > div.x78zum5.xdt5ytf.x5yr21d > div > div.x10l6tqk.x13vifvy.x1o0tod.x78zum5.xh8yej3.x5yr21d.x6ikm8r.x10wlt62.x47corl > div._aigw._as6h.false.xevlxbw.x9f619.x1n2onr6.x5yr21d.x17dzmu4.x1i1dayz.x2ipvbc.xjdofhw.x78zum5.xdt5ytf.x570efc.x18dvir5.xxljpkc.xwfak60.x6ikm8r.x10wlt62.x1oy9qf3.xpilrb4.x1t7ytsu.x1vb5itz > div > span > div > span > div > div.x1n2onr6.x11uqc5h.x9f619.x78zum5.x1okw0bk.xl2dz39.xexx8yu.x18d9i69.x73uwhe.x1qhh985.x1sy0etr.xa3a66u.x1gnnqk1.x1phvje8.xcldk2z.x7a106z.x4tpdpg > div.x1n2onr6.x9f619.x98rzlu.x6ikm8r.x10wlt62 > div > div > div > p"
        search_box = WebDriverWait(self.driver, timeout).until(
            EC.element_to_be_clickable((By.CSS_SELECTOR, search_box_selector))
        )
        sleep(0.1)
        search_box.click()
        # Type the contact number into the search box
        search_box.send_keys("+2" + contact_number)
        sleep(0.3)  # Wait for search results to appear

        # Click on the contact from the search results
        try:
            # In the contacts
            contact_chat_selector = "#app > div > div > div.x78zum5.xdt5ytf.x5yr21d > div > div.x10l6tqk.x13vifvy.x1o0tod.x78zum5.xh8yej3.x5yr21d.x6ikm8r.x10wlt62.x47corl > div._aigw._as6h.false.xevlxbw.x9f619.x1n2onr6.x5yr21d.x17dzmu4.x1i1dayz.x2ipvbc.xjdofhw.x78zum5.xdt5ytf.x570efc.x18dvir5.xxljpkc.xwfak60.x6ikm8r.x10wlt62.x1oy9qf3.xpilrb4.x1t7ytsu.x1vb5itz > div > span > div > span > div > div.x1n2onr6.x1n2onr6.xupqr0c.x78zum5.x1r8uery.x1iyjqo2.xdt5ytf.x6ikm8r.x1odjw0f.x1hc1fzr.x1anedsm.x1280gxy > div:nth-child(2) > div > div > div:nth-child(2) > div > div"
            contact = WebDriverWait(self.driver, 0.5).until(
            EC.element_to_be_clickable((By.CSS_SELECTOR,contact_chat_selector))
        )
            sleep(0.2)  # Wait for the chat to open
            contact.click()
        except TimeoutException:
            try:
                #Not in the contacts
                contact_chat_selector = "#app > div > div > div.x78zum5.xdt5ytf.x5yr21d > div > div.x10l6tqk.x13vifvy.x1o0tod.x78zum5.xh8yej3.x5yr21d.x6ikm8r.x10wlt62.x47corl > div._aigw._as6h.false.xevlxbw.x9f619.x1n2onr6.x5yr21d.x17dzmu4.x1i1dayz.x2ipvbc.xjdofhw.x78zum5.xdt5ytf.x570efc.x18dvir5.xxljpkc.xwfak60.x6ikm8r.x10wlt62.x1oy9qf3.xpilrb4.x1t7ytsu.x1vb5itz > div > span > div > span > div > div.x1n2onr6.x1n2onr6.xupqr0c.x78zum5.x1r8uery.x1iyjqo2.xdt5ytf.x6ikm8r.x1odjw0f.x1hc1fzr.x1anedsm.x1280gxy > div._ak72.false.false.false._ak73._asiw._ap1-._ap1_"
                contact = WebDriverWait(self.driver, 0.5).until(
                EC.element_to_be_clickable((By.CSS_SELECTOR,contact_chat_selector))
                )
                sleep(0.2)  # Wait for the chat to open
                contact.click()
            # number not found on whatsapp
            except TimeoutException:
                self.log_result(contact_number, True)
                clean_selector = "#app > div > div > div.x78zum5.xdt5ytf.x5yr21d > div > div.x10l6tqk.x13vifvy.x1o0tod.x78zum5.xh8yej3.x5yr21d.x6ikm8r.x10wlt62.x47corl > div._aigw._as6h.false.xevlxbw.x9f619.x1n2onr6.x5yr21d.x17dzmu4.x1i1dayz.x2ipvbc.xjdofhw.x78zum5.xdt5ytf.x570efc.x18dvir5.xxljpkc.xwfak60.x6ikm8r.x10wlt62.x1oy9qf3.xpilrb4.x1t7ytsu.x1vb5itz > div > span > div > span > div > div.x1n2onr6.x11uqc5h.x9f619.x78zum5.x1okw0bk.xl2dz39.xexx8yu.x18d9i69.x73uwhe.x1qhh985.x1sy0etr.xa3a66u.x1gnnqk1.x1phvje8.xcldk2z.x7a106z.x4tpdpg > div.x1n2onr6.x9f619.x98rzlu.x6ikm8r.x10wlt62 > span > button > span"
                clean_button = WebDriverWait(self.driver, timeout).until(
                        EC.element_to_be_clickable((By.CSS_SELECTOR, clean_selector))
                    )
                sleep(0.1)
                clean_button.click()
                return_selector = "#app > div > div > div.x78zum5.xdt5ytf.x5yr21d > div > div.x10l6tqk.x13vifvy.x1o0tod.x78zum5.xh8yej3.x5yr21d.x6ikm8r.x10wlt62.x47corl > div._aigw._as6h.false.xevlxbw.x9f619.x1n2onr6.x5yr21d.x17dzmu4.x1i1dayz.x2ipvbc.xjdofhw.x78zum5.xdt5ytf.x570efc.x18dvir5.xxljpkc.xwfak60.x6ikm8r.x10wlt62.x1oy9qf3.xpilrb4.x1t7ytsu.x1vb5itz > div > span > div > span > div > header > div > div.x1okw0bk > div > span > button > div > div > div:nth-child(1) > span"
                return_button = WebDriverWait(self.driver, timeout).until(
                        EC.element_to_be_clickable((By.CSS_SELECTOR, return_selector))
                    )
                sleep(0.1)
                return_button.click()
                self._loaction = self._start
                self.send_messages_to_all_contacts()
        

    def send_message_to_contact(self, number, message):
        try:
            # Open the chat with the contact
            
            self.open_chat_with_contact(number)
    
            sleep(random.uniform(0.4, 0.5))  # Random delay to simulate human behavior

            # Locate the message box
            message_box_selector = "#main > footer > div.x1n2onr6.xhtitgo.x9f619.x78zum5.x1q0g3np.xuk3077.xjbqb8w.x1wiwyrm.xvc5jky.x11t971q.xquzyny.xnpuxes.copyable-area > div > span > div > div._ak1r > div > div.x1n2onr6.xh8yej3.xjdcl3y.lexical-rich-text-input > div.x1hx0egp.x6ikm8r.x1odjw0f.x1k6rcq7.x6prxxf > p"
            message_box = WebDriverWait(self.driver, timeout).until(
                EC.presence_of_element_located((By.CSS_SELECTOR, message_box_selector))
            )
            print("Message box located successfully.")

            # Click the message box to ensure focus
            message_box.click()
            sleep(0.1)  # Short sleep to ensure the box is in focus

            # Clear the message box before typing the message
            message_box.clear()

            # Type the message into the message box
            self.type_message(message_box, message)

            # Locate and click the send button
            send_button_selector = "#main > footer > div.x1n2onr6.xhtitgo.x9f619.x78zum5.x1q0g3np.xuk3077.xjbqb8w.x1wiwyrm.xquzyny.xvc5jky.x11t971q.xnpuxes.copyable-area > div > span > div > div._ak1r > div > div.x9f619.x78zum5.x6s0dn4.xl56j7k.xpvyfi4.x2lah0s.x1c4vz4f.x1fns5xo.x1ba4aug.x1c9tyrk.xeusxvb.x1pahc9y.x1ertn4p.x1pse0pq.xpcyujq.xfn3atn.x1ypdohk.x1m2oepg > div > span > button > div > div > div:nth-child(1) > span"
            send_button = WebDriverWait(self.driver, timeout).until(
                EC.element_to_be_clickable((By.CSS_SELECTOR, send_button_selector))
            )

            print("Send button located successfully.")
            send_button.click()

            # Introduce a random sleep to avoid detection as a bot
            sleep(random.uniform(0.4, 0.6))

            print(Fore.GREEN, "Message sent successfully.", Style.RESET_ALL)
            return False  # No error

        except Exception as e:
            print(e)
            print(Fore.RED, "Error sending message.", Style.RESET_ALL)
            return True  # Error occurred

    def send_messages_to_all_contacts(self):
        """
        Sends messages to all contacts listed in the provided CSV file.
        Closes the driver after execution.
        """
        if not os.path.isfile(self._csv_numbers):
            print(Fore.RED, "CSV file not found!", Style.RESET_ALL)
            return

        try:
            with open(self._csv_numbers, mode="r", encoding="utf-8") as file:
                csv_reader = csv.reader(file)

                self._start = 0
                for row in csv_reader:
                    
                    if((self._start > 0) & (self._start>self._loaction)):
                        split_message = row[0].split(",")
                        number = split_message[0]
                        msg = split_message[1]
                        print(f"Sending message to: | {number}")
                        error = self.send_message_to_contact(number, msg)
                        self.log_result(number, error)
                        #Random sleep between sending messages to avoid being detected
                        sleep(random.uniform(3, 4))
                    self._start += 1

        finally:
            sleep(3.5)
            self.quit_driver()
            

    def type_message(self, text_element, message):
        """
        Types the message into the appropriate text element.
        Handles multiline messages.
        """
        multiline = "\n" in message
        if multiline:
            for line in message.split("\n"):
                text_element.send_keys(line)
                text_element.send_keys(Keys.LEFT_SHIFT + Keys.RETURN)
        else:
            text_element.send_keys(message)

    def wait_for_element_to_be_clickable(self, xpath, success_message=None, error_message=None, timeout=timeout):
        """
        Waits for an element to be clickable within the specified timeout period.
        :param xpath: The XPATH of the element to wait for.
        :param success_message: Message to display when the element becomes clickable.
        :param error_message: Message to display in case of timeout.
        :param timeout: Time (in seconds) to wait for the element to become clickable.
        :return: True if the element becomes clickable, False otherwise.
        """
        try:
            # Wait for the element to become clickable
            WebDriverWait(self.driver, timeout).until(
                EC.element_to_be_clickable((By.XPATH, xpath))
            )
            if success_message:
                print(Fore.GREEN + success_message + Style.RESET_ALL)
            return True  # Element is clickable, return True

        except TimeoutException:
            if error_message:
                print(Fore.RED + error_message + Style.RESET_ALL)
            return False  # Timeout occurred, return False

    @property
    def csv_numbers(self):
        return self._csv_numbers

    @csv_numbers.setter
    def csv_numbers(self, csv_file):
        self._csv_numbers = csv_file

    @property
    def options(self):
        return self._options

    @options.setter
    def options(self, opt):
        self._options = opt
