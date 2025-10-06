import fs from "fs";
import { resolve } from "path";

const fsPromises = fs.promises;

export async function getCurrentDir() {
    return resolve('./', '');
}


export async function getFile(dir: string, filename: string): Promise<Array<string>> {
    const dirents = await fsPromises.readdir(dir, { withFileTypes: true });
    const files = await Promise.all(dirents.map((dirent) => {
        const res = resolve(dir, dirent.name);
        return dirent.isDirectory() ? getFile(res, filename) : res;
    }));
    const arr = Array.prototype.concat(...files);

    return arr.filter((s) => s.includes(filename));
}

export async function changeConstantInFile(dir: string, filename: string, variable: string, value: any) {
    const filepath = (await getFile(dir, filename))[0];
    const isJsFile = filepath.indexOf('.js') !== -1;

    const data = await fsPromises.readFile(filepath, 'utf8');

    const regex = new RegExp(`${variable}( )*=.*`, 'g');

    let result = '';

    if (isJsFile) {
        result = data.replace(regex, `${variable} = '${value}';`);
    } else {
        result = data.replace(regex, `${variable} = ${value};`);
    }

    await fsPromises.writeFile(filepath, result, 'utf8');
}


export async function changeConstantInFiles(dir: string, filenames: Array<string>, variable: string, value: any) {
    const filePromises = filenames.map((f) => changeConstantInFile(dir, f, variable, value));

    await Promise.all(filePromises);
}

