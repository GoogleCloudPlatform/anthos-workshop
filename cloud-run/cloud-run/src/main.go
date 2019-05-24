package main

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"

	"cloud.google.com/go/storage"
	vision "cloud.google.com/go/vision/apiv1"
)

// TODO:
// consolidate to single storage client
// wrong file type when uploaded

type PubSubMessage struct {
	Message struct {
		Data []byte `json:"data,omitempty"`
		ID   string `json:"id"`
	} `json:"message"`
	Subscription string `json:"subscription"`
}

// being a little lazy here
// converting everything to string (even for numeric types)
// TODO: apply correct data types
type GcsPubSubMessage struct {
	Kind                    string `json:"kind"`
	Id                      string `json:"id"`
	SelfLink                string `json:"selfLink"`
	Name                    string `json:"name"`
	Bucket                  string `json:"bucket"`
	Generation              string `json:"generation"`
	Metageneration          string `json:"metageneration"`
	ContentType             string `json:"contentType"`
	TimeCreated             string `json:"timeCreated"`
	Updated                 string `json:"updated"`
	StorageClass            string `json:"storageClass"`
	TimeStorageClassUpdated string `json"timeStorageClassUpdated"`
	Size                    string `json:"size"`
	Md5Hash                 string `json:"md5Hash"`
	MediaLink               string `json:"mediaLink"`
	Crc32c                  string `json:"crc32c"`
	Etag                    string `json:"etag"`
}

// do some basic setup for logging
func init() {
	log.SetPrefix("LOG: ")
	log.SetFlags(log.Ldate | log.Lmicroseconds | log.Llongfile)
	log.Println("init started")
}

// simple function to check errors in writing to a local file
func check(e error) {
	if e != nil {
		panic(e)
	}
}

// simple function to find if a given string is in a slice; used to validate supported image formats
func stringInSlice(a string, list []string) bool {
	for _, b := range list {
		if b == a {
			return true
		}
	}
	return false
}

// pull down object from GCS and return local path
func downloadObject(filePath string, bucketName string) (string, error) {

	fmt.Println("reading from bucket: ", bucketName)
	ctx := context.Background()
	client, err := storage.NewClient(ctx)
	if err != nil {
		// TODO: Handle error.
		log.Fatal(err)
		//return ""
	}

	rc, err := client.Bucket(bucketName).Object(filePath).NewReader(ctx)
	if err != nil {
		log.Printf("Can't read from bucket")
		return "", err
	}
	log.Printf("Can read from bucket")
	defer rc.Close()

	data, err := ioutil.ReadAll(rc)
	if err != nil {
		log.Printf("Can't read from object")
		return "", err
	}
	log.Printf("Can read from object")

	localObjectPath := "/vision_scratch/" + filePath
	// creating local directories if they don't exist
	if strings.Contains(filePath, "/") {
		log.Printf("Need to create local subdirectory from /vision_scratch/: %s", filepath.Dir(filePath))
		if _, err := os.Stat("/vision_scratch/" + filepath.Dir(filePath)); os.IsNotExist(err) {
			log.Printf("Creating directory %s", "/vision_scratch/"+filepath.Dir(filePath)+"/")
			pathErr := os.MkdirAll("/vision_scratch/"+filepath.Dir(filePath), 0700)

			if pathErr != nil {
				log.Fatal(pathErr)
			} else {
				log.Printf("Created directory %s", "/vision_scratch/"+filepath.Dir(filePath)+"/")
			}

		}
	}

	log.Printf("Writing to local file %s", localObjectPath)
	f, err := os.Create(localObjectPath)
	defer f.Close()
	fw, err := f.Write(data)
	log.Printf("wrote %d bytes\n", fw)
	f.Sync()

	return localObjectPath, nil

}

func uploadObject(localFilePath string, remoteFilePath string, bucketName string) error {

	ctx := context.Background()
	client, err := storage.NewClient(ctx)
	if err != nil {
		// TODO: Handle error.
		log.Fatal(err)
		//return ""
	}

	f, err := os.Open(localFilePath)
	if err != nil {
		return err
	}
	defer f.Close()

	wc := client.Bucket(bucketName).Object(remoteFilePath).NewWriter(ctx)
	wc.ContentType = "application/json"
	if _, err = io.Copy(wc, f); err != nil {
		return err
	}
	if err := wc.Close(); err != nil {
		return err
	}

	return nil
}

func getVisionAnnotation(localPath string) string {

	ctx := context.Background()

	// Creates a client.
	client, err := vision.NewImageAnnotatorClient(ctx)
	if err != nil {
		log.Fatalf("Failed to create client: %v", err)
	}
	defer client.Close()

	file, err := os.Open(localPath)

	if err != nil {
		log.Fatalf("Failed to read file: %v", err)
	}
	defer file.Close()
	image, err := vision.NewImageFromReader(file)
	if err != nil {
		log.Fatalf("Failed to create image: %v", err)
	}

	labels, err := client.DetectLabels(ctx, image, nil, 10)
	if err != nil {
		log.Fatalf("Failed to detect labels: %v", err)
	}

	log.Printf("Writing to file %s", localPath+".json")
	f, err := os.Create(localPath + ".json")
	check(err)
	defer f.Close()

	json, err := json.MarshalIndent(labels, "", "  ")
	if err != nil {
		log.Fatal(err)
	}

	log.Println("Annotation results from Google Vision API:")
	log.Println(string(json))

	n3, err := f.WriteString(string(json))
	log.Printf("wrote %d bytes\n", n3)

	f.Sync()

	return localPath + ".json"

}

func formatRequest(r *http.Request) string {
	// Create return string
	var request []string
	// Add the request string
	url := fmt.Sprintf("%v %v %v", r.Method, r.URL, r.Proto)
	request = append(request, url)
	// Add the host
	request = append(request, fmt.Sprintf("Host: %v", r.Host))
	// Loop through headers
	for name, headers := range r.Header {
		name = strings.ToLower(name)
		for _, h := range headers {
			request = append(request, fmt.Sprintf("%v: %v", name, h))
		}
	}

	// If this is a POST, add post data
	if r.Method == "POST" {
		r.ParseForm()
		request = append(request, "\n")
		request = append(request, r.Form.Encode())
	}
	// Return the request as a string
	return strings.Join(request, "\n")
}

func basePath(w http.ResponseWriter, r *http.Request) {
	if r.URL.Path != "/" {
		http.Error(w, "404 not found.", http.StatusNotFound)
		return
	}
	switch r.Method {
	case "GET":
		message := r.URL.Path
		message = strings.TrimPrefix(message, "/")
		message = "Hi there! You've attempted a GET against this Cloud Run service, but it's designed for POSTs from PubSub. Try that instead! " + message
		log.Println(message)
		w.Write([]byte(message))
	case "POST":
		// Parse the Pub/Sub message.
		var m PubSubMessage

		// String array containing supported image formats / contentTypes
		var supportedFormats = []string{"image/jpeg", "image/tiff", "image/png", "image/bmp", "image/gif"}

		if err := json.NewDecoder(r.Body).Decode(&m); err != nil {
			log.Printf("json.NewDecoder: %v", err)
			http.Error(w, "Bad Request", http.StatusBadRequest)
			return
		}

		//md := string(m.Message.Data)
		var pm GcsPubSubMessage
		s := string(m.Message.Data)
		err := json.NewDecoder(strings.NewReader(s)).Decode(&pm)
		if err != nil {
			fmt.Println(err)
			return
		}

		if stringInSlice(pm.ContentType, supportedFormats) {
			log.Printf("File type %s supported. Processing...", pm.ContentType)

			localObjectPath, err := downloadObject(pm.Name, pm.Bucket)
			if err != nil {
				log.Fatalf("Cannot read object: %v", err)
			}

			log.Printf("Local object path: %s\n", localObjectPath)

			// time to call Vision API
			localJSONPath := getVisionAnnotation(localObjectPath)
			log.Printf(localJSONPath)

			if err := uploadObject(localJSONPath, pm.Name+".json", pm.Bucket); err != nil {
				log.Fatalf("Cannot write object: %v", err)
			} else {
				log.Printf("Successfully wrote object: %s", pm.Name+".json")
			}

		} else {
			log.Printf("File type %s not supported. Exiting...", pm.ContentType)
			return
		}

	default:
		log.Println("Sorry, only GET and POST methods are supported.")
	}
}
func main() {
	log.Println("main started")
	http.HandleFunc("/", basePath)
	if err := http.ListenAndServe(":8080", nil); err != nil {
		log.Panicln(err)
	}
}
