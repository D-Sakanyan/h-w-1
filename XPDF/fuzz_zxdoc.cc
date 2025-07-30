/*  Copyright 2020 Google Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include "Zoox.h"
#include <iostream>
#include <fstream>
#include <filesystem>
#include <vector>
//#include <chrono>

namespace fs = std::filesystem;

//auto start = high_resolution_clock::now();

extern "C" int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
    char *ss = (char*)malloc(size+1);
    std::cout << "processing input size: " << size << std::endl;
    memcpy(ss, data, size);
    ss[size] = '\0';

    ZxDoc Z1;
    ZxDoc *new_doc = Z1.loadMem(ss, size);
    if (new_doc != NULL)
        delete new_doc;

    free(ss);

    return 0;
}

void processFile(const fs::path& filePath) {
    std::ifstream file(filePath, std::ios::binary);
    if (!file) {
        std::cerr << "Failed to open file: " << filePath << std::endl;
        return;
    }

    std::vector<uint8_t> buffer((std::istreambuf_iterator<char>(file)), std::istreambuf_iterator<char>());

    if (!buffer.empty()) {
        LLVMFuzzerTestOneInput(buffer.data(), buffer.size());
    }
}

int main(int argc, char *argv[]) {
    if (argc < 2) {
        std::cerr << "Usage: " << argv[0] << " <corpus_directory>" << std::endl;
        return 1;
    }

    fs::path corpusDir = argv[1];

    if (!fs::exists(corpusDir) || !fs::is_directory(corpusDir)) {
        std::cerr << "Invalid corpus directory: " << corpusDir << std::endl;
        return 1;
    }

    for (const auto& entry : fs::directory_iterator(corpusDir)) {
        if (fs::is_regular_file(entry)) {
            processFile(entry.path());
        }
    }

    return 0;
}
