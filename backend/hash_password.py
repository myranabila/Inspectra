from argon2 import PasswordHasher

ph = PasswordHasher()

def hash_password():
    password = input("Enter password to hash: ")
    hashed = ph.hash(password)
    print("\nHashed Password (Argon2):")
    print(hashed)

if __name__ == "__main__":
    hash_password()
