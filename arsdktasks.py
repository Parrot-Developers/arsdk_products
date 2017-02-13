
import os
import dragon

#===============================================================================
#===============================================================================

# For compatibility with previous output directory hierarchy
def create_android_compat_symlink(abi):
    dragon.relative_symlink(os.path.join(dragon.OUT_DIR, abi),
            os.path.join(dragon.OUT_DIR, "..", "Android-%s" % abi))

def create_ios_compat_symlink():
    dragon.relative_symlink(os.path.join(dragon.OUT_DIR),
            os.path.join(dragon.OUT_DIR, "..", "iOS-iphoneos"))

def create_ios_sim_compat_symlink():
    dragon.relative_symlink(os.path.join(dragon.OUT_DIR),
            os.path.join(dragon.OUT_DIR, "..", "iOS-iphonesimulator"))

def create_native_compat_symlink():
    dragon.relative_symlink(os.path.join(dragon.OUT_DIR),
            os.path.join(dragon.OUT_DIR, "..", "Unix-base"))

def create_windows_compat_symlink():
    dragon.relative_symlink(os.path.join(dragon.OUT_DIR),
            os.path.join(dragon.OUT_DIR, "..", "Windows-base"))

#===============================================================================
#===============================================================================
def setup_android_abi(task, abi):
    task.extra_env["ANDROID_ABI"]=abi

# Register a task to build android sdk for a specific abi/arch
def add_android_abi(abi):
    dragon.add_alchemy_task(
        name = "alchemy-%s" % abi,
        desc = "Run alchemy task for %s" % abi,
        product = dragon.PRODUCT,
        variant = dragon.VARIANT,
        prehook = lambda task, args: setup_android_abi(task, abi),
        posthook = lambda task, args: create_android_compat_symlink(abi),
        weak = True,
        outsubdir = abi
    )

#===============================================================================
#===============================================================================
if dragon.VARIANT == "android":
    # Register all abi/arch
    add_android_abi("armeabi")
    add_android_abi("armeabi-v7a")
    add_android_abi("mips")
    add_android_abi("x86")
    add_android_abi("arm64-v8a")

    # Meta-task to build all sdk abi/arch
    dragon.add_meta_task(
        name="build-sdk",
        desc="Build android sdk for all architectures",
        subtasks=[
            "alchemy-armeabi all sdk",
            "alchemy-armeabi-v7a all sdk",
            "alchemy-mips all sdk",
            "alchemy-x86 all sdk",
            "alchemy-arm64-v8a all sdk",
        ],
        weak=True
    )

    # add clean-sdk to clean all abi/arch
    dragon.add_meta_task(
        name="clean-sdk",
        desc = "Clean android sdk for all architectures",
        subtasks=[
            "alchemy clobber",
            "alchemy-armeabi clobber",
            "alchemy-armeabi-v7a clobber",
            "alchemy-mips clobber",
            "alchemy-x86 clobber",
            "alchemy-arm64-v8a clobber",
        ]
    )

#===============================================================================
#===============================================================================
if dragon.VARIANT == "ios":
    dragon.add_alchemy_task(
        name = "build-sdk",
        desc = "Build ios sdk",
        product = dragon.PRODUCT,
        variant = dragon.VARIANT,
        defargs = ["all","sdk"],
        posthook = lambda task, args: create_ios_compat_symlink(),
        weak = True,
    )
    dragon.add_meta_task(
        name="clean-sdk",
        desc = "Clean ios sdk",
        subtasks=["alchemy clobber"]
    )

#===============================================================================
#===============================================================================
if dragon.VARIANT == "ios_sim":
    dragon.add_alchemy_task(
        name = "build-sdk",
        desc = "Build ios simulator sdk",
        product = dragon.PRODUCT,
        variant = dragon.VARIANT,
        defargs = ["all","sdk"],
        posthook = lambda task, args: create_ios_sim_compat_symlink(),
        weak = True,
    )
    dragon.add_meta_task(
        name="clean-sdk",
        desc = "Clean ios simulator sdk",
        subtasks=["alchemy clobber"]
    )

if dragon.VARIANT == "native":
    dragon.add_alchemy_task(
        name = "build-sdk",
        desc = "Build native sdk",
        product = dragon.PRODUCT,
        variant = dragon.VARIANT,
        defargs = ["all"],
        posthook = lambda task, args: create_native_compat_symlink(),
        weak = True,
    )
    dragon.add_meta_task(
        name="clean-sdk",
        desc = "Clean native sdk",
        subtasks=["alchemy clobber"]
    )

if dragon.VARIANT == "windows":
    dragon.add_alchemy_task(
        name = "build-sdk",
        desc = "Cross-compile sdk for windows",
        product = dragon.PRODUCT,
        variant = dragon.VARIANT,
        defargs = ["all"],
        posthook = lambda task, args: create_windows_compat_symlink(),
        weak = True,
    )
    dragon.add_meta_task(
        name="clean-sdk",
        desc="Clean windows SDK",
        subtasks=["alchemy clobber"]
    )
