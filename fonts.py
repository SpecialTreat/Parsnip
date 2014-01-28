
min_font = 7
font_step = 0.5

min_width = 240.0
max_width = 2560.0
width_step = 18.0

width = 0
font = 0

count = int((max_width - min_width) / width_step)
max_font_str = str(min_font + (count * font_step)).rstrip('0').rstrip('.')
max_width_str = str(max_width).rstrip('0').rstrip('.')

print('''html{font-size:16px}''')
print('''@media all and (min-width:{0}px) and (min-height:{0}px){{html{{font-size:{1}px}}}}'''.format(max_width_str, max_font_str))

template = '''@media all and (max-width:{0}px), all and (max-height:{0}px){{html{{font-size:{1}px}}}}'''

print(template.format(max_width_str, max_font_str))
for i in xrange(count - 1, -1, -1):
    width = str(min_width + (i * width_step)).rstrip('0').rstrip('.')
    font = str(min_font + (i * font_step)).rstrip('0').rstrip('.')
    print(template.format(width, font))
