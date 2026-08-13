import paramiko, time, re, sys
ENV=("export LD_LIBRARY_PATH=/qt/lib:/proc/boot:/lib:/usr/lib:/lib/dll:/lib/dll/pci:/opt/someip/libs:/usr/lib/graphics/iMX8QM; "
     "export QT_PLUGIN_PATH=/qt/plugins QML_IMPORT_PATH=/qt/qml QT_QUICK_CONTROLS_STYLE=Basic; "
     "export QQNX_PHYSICAL_SCREEN_SIZE=154,87; export QSG_RENDER_TIMING=1; export QT_FORCE_STDERR_LOGGING=1; "
     "export FONTCONFIG_FILE=/tmp/fonts.conf; ")
APP = sys.argv[1]
NAME = APP.rsplit("/",1)[-1]
c=paramiko.SSHClient(); c.set_missing_host_key_policy(paramiko.AutoAddPolicy())
c.connect("192.168.1.51",username="qnxuser",password="qnxuser",timeout=15)
def sh(cmd,t=60):
    _,o,e=c.exec_command(cmd,timeout=t); return o.read().decode(errors="replace")

def kill_all():
    """Slay by the REAL basename and then VERIFY. A previous sweep slayed the
    wrong name (left over from a sed that only rewrote the path), so three
    instances accumulated and every number was contaminated -- 'whole bar off'
    read 20 ms instead of 7. Never assume the kill worked."""
    for _ in range(6):
        sh(f"slay {NAME} 2>/dev/null; true"); time.sleep(1.0)
        n = sh(f"pidin ar 2>/dev/null | grep {NAME} | grep -vc grep").strip()
        if n in ("0",""):
            return True
    return False

if not kill_all():
    sys.exit(f"FATAL: could not clear running {NAME} instances; refusing to measure.")

for spec in sys.argv[2:]:
    label,args = spec.split("|",1)
    log="/tmp/s.log"
    sh(f"rm -f {log}; {ENV} {APP} {args} >{log} 2>&1 &")
    time.sleep(9)
    txt=sh(f"cat {log}")
    if not kill_all():
        print(f"{label:30s}  FATAL: leftover instance, discarding"); continue
    ren=[int(m) for m in re.findall(r'render=(\d+)',txt)][150:]
    ani=[int(m) for m in re.findall(r'animations=(\d+) ms',txt)][150:]
    per=[p for p in (int(m) for m in re.findall(r'render thread.*elapsed since last call: (\d+) ms',txt)) if p<100][150:]
    md=lambda a: sorted(a)[len(a)//2] if a else -1
    fps=len(per)/(sum(per)/1000.0) if per else 0
    print(f"{label:30s} render_p50={md(ren):3d}  anim_p50={md(ani):3d}  period_p50={md(per):3d}  fps={fps:5.1f}")
c.close()
