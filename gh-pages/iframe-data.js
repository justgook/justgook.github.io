(function () {
  function $worker() { //https://github.com/deebloo/worker
    var workers = []

    // PUBLIC_API
    return {
      create: create,
      runAll: runAll,
      terminateAll: terminateAll,
      list: list
    }

    /**
     * create a new worker instance and saves it to the list
     *
     * @param {Function} fn - the function to run in the worker
     */
    function create(fn, otherScripts) {
      var newWorker = _createWorker.apply(null, arguments)

      workers.push(newWorker)

      return newWorker
    }

    /**
     * run all of the workers in the array and resolve all
     */
    function runAll(data) {
      var promises = workers.map(function (worker) {
        return worker.run(data)
      })

      return Promise.all(promises)
    }

    /**
     * terminate all workers
     */
    function terminateAll() {
      workers.forEach(function (worker) {
        worker._shell.terminate()
      })

      workers.length = 0
    }

    /**
     * returns the list of current workers
     */
    function list() {
      return workers
    }

    /**
     * Create an actual web worker from an object url from a blob
     *
     * @param {Function} fn - the function to be put into the blog array.
     */
    function _createWorker(fn, otherScripts) {
      otherScripts = otherScripts || []

      var blobArray = otherScripts.map(function (script) {
        return 'self.' + script.name + '=' + script.value.toString() + ';'
      })
      blobArray = blobArray.concat(['self.onmessage=', fn.toString(), ''])

      var blob = new Blob(blobArray, { type: 'text/javascript' })
      var url = URL.createObjectURL(blob)

      return {
        // the web worker instance
        _shell: (function () {
          var worker = new Worker(url)

          URL.revokeObjectURL(url)

          return worker
        })(),

        // run the web worker
        run: function (data) {
          return __run(this._shell, data)
        },

        // terminate the web worker
        terminate: function () {
          return __terminate(this)
        },

        // subscribe to the worker
        subscribe: function (fn) {
          this._shell.addEventListener('message', fn)
        },

        // ubsubscribe from the worker
        unsubscribe: function (fn) {
          this._shell.removeEventListener('message', fn)
        }
      }
    }

    /**
     * run the passed in web worker
     */
    function __run(worker, data) {
      data = data || {}

      worker.postMessage(data)

      var promise = new Promise(function (resolve, reject) {
        worker.onmessage = resolve
        worker.onerror = reject
      })

      return promise
    }

    /**
     * terminate the web worker
     */
    function __terminate(ref) {
      workers.splice(workers.indexOf(ref), 1)

      return ref._shell.terminate()
    }
  }

  // ------------------------------------------------------------------------------------------------------------------------------------------------
  // lodashOnce

  function once(func) {
    function before(n, func) {
      let result
      if (typeof func != 'function') {
        throw new TypeError('Expected a function')
      }
      return function (...args) {
        if (--n > 0) {
          result = func.apply(this, args)
        }
        if (n <= 1) {
          func = undefined
        }
        return result
      }
    }
    return before(2, func)
  }
  // ------------------------------------------------------------------------------------------------------------------------------------------------

  const template = document.createElement('template')
  template.innerHTML = `<link rel="stylesheet" href="//cdnjs.cloudflare.com/ajax/libs/highlight.js/9.12.0/styles/github.min.css" />`
    + `<link rel="stylesheet" href="/tabs.css" />`

  function resizeIframe(obj) {
    obj.style.height = obj.contentWindow.document.body.scrollHeight + 'px';
  }
  const workerServiceOnce = once(() => {
    const workerFunc = function (e) {
      magicImport()
      var result = e.data.lang ? self.hljs.highlight(e.data.lang, e.data.data) : self.hljs.highlightAuto(e.data.data)
      self.postMessage({ income: e.data, value: result.value })
    }
    const scriptMap = [
      { name: 'once', value: once },
      {
        name: 'magicImport',
        value: `once(function () {
          importScripts('https://cdnjs.cloudflare.com/ajax/libs/highlight.js/9.12.0/highlight.min.js')
        })`
      }
    ]
    return $worker().create(workerFunc, scriptMap)
  });

  const workerService = (income) => {
    const worker = workerServiceOnce()
    return new Promise(function (resolve, reject) {
      worker.run(income).then(() => null, reject)
      const sub = ({ data }) => {
        if (data.income.data == income.data && data.income.lang == income.lang) {
          worker.unsubscribe(sub)
          resolve(data.value)
        }
      }
      worker.subscribe(sub)
    })
  }
  function click(enable, disable) {
    return () => {
      enable.map((item) => item.classList.add("active"))
      disable.map((item) => item.classList.remove("active"))
    }
  }
  function createTab(name) {
    const content = document.createElement('div')
    content.className = "tabcontent"
    content.id = name

    const tab = document.createElement("button")
    tab.type = "button"
    tab.className = "tablinks"
    tab.innerText = name
    return { tab, content }
  }

  class IframeData extends HTMLElement {

    constructor() {
      super()
      const clone = document.importNode(template.content, true)
      this.attachShadow({ mode: 'open' }).appendChild(clone)
      const code = document.createElement('code')
      const pre = document.createElement('pre')
      const result = document.createDocumentFragment()
      code.textContent = this.innerHTML
      pre.appendChild(code)
      result.appendChild(pre)

      workerService({ lang: this.getAttribute('lang'), data: this.textContent })
        .then(function (data_) { code.innerHTML = data_ })

      const src = this.getAttribute('src')
      if (src) {
        const iframe = document.createElement('iframe')
        const haveCode = !!this.getAttribute('data')
        const data = this.getAttribute('data') || this.textContent

        iframe.src = `${src}?${data}`
        iframe.frameBorder = 0
        iframe.scrolling = "no"


        const tabs = document.createElement('div')
        tabs.className = "tab"
        result.appendChild(tabs)

        const exampleTab = createTab("Example")
        exampleTab.content.appendChild(iframe)

        const dataTab = createTab("Data")
        dataTab.content.appendChild(pre)

        const exampleClick = [[exampleTab.tab, exampleTab.content], [dataTab.tab, dataTab.content]]
        const dataClick = [[dataTab.tab, dataTab.content], [exampleTab.tab, exampleTab.content]]

        result.appendChild(exampleTab.content)
        result.appendChild(dataTab.content)

        if (haveCode) {
          const codeTab = createTab("Code");

          const codeClick = [[codeTab.tab, codeTab.content], [dataTab.tab, dataTab.content, exampleTab.tab, exampleTab.content]]
          exampleClick[1].push.apply(exampleClick[1], [codeTab.tab, codeTab.content])
          dataClick[1].push.apply(dataClick[1], [codeTab.tab, codeTab.content])

          codeTab.tab.addEventListener("click", click.apply(null, codeClick))
          tabs.appendChild(codeTab.tab)
          result.appendChild(codeTab.content)
          codeTab.content.appendChild(pre)

          const code2 = document.createElement('code')
          const pre2 = document.createElement('pre')
          pre2.appendChild(code2)
          dataTab.content.appendChild(pre2)

          workerService({ lang: "json", data: this.getAttribute('data').replace(/\\n/mig, "\n") })
            .then(function (data_) { code2.innerHTML = data_ })
        }

        click.apply(null, exampleClick)()
        iframe.onload = () => resizeIframe(iframe)
        exampleTab.tab.addEventListener("click", () => {
          click.apply(null, exampleClick)()
          resizeIframe(iframe)
        })

        dataTab.tab.addEventListener("click", click.apply(null, dataClick))
        tabs.appendChild(exampleTab.tab)
        tabs.appendChild(dataTab.tab)


      }

      this.shadowRoot.appendChild(result)

    }

    connectedCallback() {
      console.log("connectedCallback")
    }
    disconnectedCallback() {
      console.log("disconnectedCallback")
    }
    attributeChangedCallback(attrName, oldVal, newVal) {
      console.log("attributeChangedCallback")
    }
  }
  customElements.define('iframe-code', IframeData)
})()