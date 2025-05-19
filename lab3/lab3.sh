#!/bin/bash

# Проверка корректности аргументов
if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    echo "Использование: $0 <исходная_папка> [целевая_папка]"
    exit 1
fi

# Параметры скрипта
source_dir="$1"
backup_root="${2:-$(pwd)}"
timestamp=$(date +'%Y%m%d_%H%M%S')
backup_dir="${backup_root}/backup_${timestamp}"

# Проверка существования исходной директории
if [ ! -d "${source_dir}" ]; then
    echo "Ошибка: исходная папка '${source_dir}' не существует" >&2
    exit 1
fi

# Создание директории для бэкапа
if ! mkdir -p "${backup_dir}"; then
    echo "Ошибка: не удалось создать папку бэкапа '${backup_dir}'" >&2
    exit 1
fi

echo "Начато резервное копирование из: ${source_dir}"
echo "Целевая директория: ${backup_dir}"

# Список поддерживаемых расширений
extensions=(
    jpg jpeg 
    png gif 
    bmp tiff 
    webp
)

# Формирование условий поиска для find
find_pattern=()
for ext in "${extensions[@]}"; do
    [ ${#find_pattern[@]} -gt 0 ] && find_pattern+=(-o)
    find_pattern+=(-iname "*.${ext}")
done

# Копирование файлов с сохранением структуры
count=0
while IFS= read -r -d '' file; do
    rel_path="${file#${source_dir}/}"
    target_folder="${backup_dir}/$(dirname "${rel_path}")"
    
    mkdir -p "${target_folder}" || continue
    if cp -v "${file}" "${backup_dir}/${rel_path}"; then
        ((count++))
    else
        echo "Ошибка: не удалось скопировать '${file}'" >&2
    fi
done < <(find "${source_dir}" -type f \( "${find_pattern[@]}" \) -print0 2>/dev/null)

# Итоговый отчет
echo "Копирование завершено. Скопировано файлов: ${count}"
if [ ${count} -eq 0 ]; then
    echo "Внимание: не найдено файлов изображений для копирования" >&2
    exit 2
fi

exit 0