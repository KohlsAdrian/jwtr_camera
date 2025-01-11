

const baseUrl = 'http://192.168.0.245'
const rebootAPI = `${baseUrl}/form/reboot`
const presetSetAPI = `${baseUrl}/form/presetSet`
const setPTZCfgAPI = `${baseUrl}/form/setPTZCfg`
const headers = { 'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8' }

function fetchWithTimeout(url, options = {}, timeout = 1000) {
    // Create an AbortController instance
    const controller = new AbortController();
    const { signal } = controller;

    // Start the fetch request, passing the signal for cancellation
    console.log(url)
    console.log(options)
    const fetchPromise = fetch(url, { ...options, signal, mode: 'no-cors' });

    // Create a timeout promise
    const timeoutPromise = new Promise((_, reject) => {
        setTimeout(() => {
            // Abort the fetch request
            controller.abort();
            reject(new Error("Request timed out"));
        }, timeout);
    });

    // Return a race between fetch and timeout
    return Promise.race([fetchPromise, timeoutPromise]);
}
document.querySelectorAll('.main-container button').forEach(button => {

    button.addEventListener('click', function () {

        const presetNum = this.getAttribute('data-preset-num');
        if (!presetNum) return;

        const params = new URLSearchParams();
        params.append('flag', '4');
        params.append('existFlag', '1');
        params.append('language', 'cn');
        params.append('presetNum', presetNum);

        const request = {
            method: 'POST',
            headers: headers,
            body: params.toString()
        }

        fetchWithTimeout(presetSetAPI, request)
            .catch((error) => console.log(error));
    });

    button.addEventListener('click', function () {

        const presetNum = this.getAttribute('data-command');
        if (!presetNum) return;
        const request = { method: 'GET' }

        fetchWithTimeout(rebootAPI, request)
            .catch((error) => console.log(error));
    });
});
document.querySelectorAll('.commands button').forEach(button => {
    button.addEventListener('click', async function () {

        const form = this.getAttribute('data-command');
        if (!form) return;

        const params = new URLSearchParams();
        params.append('command', form);
        params.append('ZFSpeed', 0);
        params.append('PTSpeed', 0);
        params.append('panSpeed', 1);
        params.append('tiltSpeed', 1);
        params.append('focusSpeed', 2);
        params.append('FocusMode', 2);
        params.append('zoomSpeed', 2);
        params.append('standBy', 0);

        var request = {
            method: 'POST',
            headers: headers,
            body: params.toString()
        }

        try {
            fetchWithTimeout(setPTZCfgAPI, request)
                .catch((error) => console.log(error));
        } catch (error) {
            console.log(error)
        } finally {
            await new Promise(r => setTimeout(r, 100));
        }

        params.set('command', 0)
        request = {
            method: 'POST',
            headers: headers,
            body: params.toString()
        }

        try {
            fetchWithTimeout(setPTZCfgAPI, request)
                .catch((error) => console.log(error));
        } catch (error) {
            console.log(error)
        }

        params.set('command', 55)
        request = {
            method: 'POST',
            headers: headers,
            body: params.toString()
        }
        try {
            fetchWithTimeout(setPTZCfgAPI, request)
                .catch((error) => console.log(error));
        } catch (error) {
            console.log(error)
        }

        params.set('command', 0)
        request = {
            method: 'POST',
            headers: headers,
            body: params.toString()
        }

        try {
            fetchWithTimeout(setPTZCfgAPI, request)
                .catch((error) => console.log(error));
        } catch (error) {
            console.log(error)
        }
    });
});

/** MIME Type: application/x-www-form-urlencoded; charset=UTF-8

=> command: ? | int
ZFSpeed: 0
PTSpeed: 0
panSpeed: 1
tiltSpeed: 1
focusSpeed: 2
FocusMode: 3
zoomSpeed: 2
standBy: 0
 */