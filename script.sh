# Install the required dependency
npm install youtubei.js

# Create the index.js file
cat > index.js << EOL
let Innertube;

exports.handler = async (event) => {
    if (!Innertube) {
        const { Innertube: InnertubeModule } = await import('youtubei.js');
        Innertube = InnertubeModule;
    }

    let youtube;

    const fetchTranscript = async (url) => {
        try {
            if (!youtube) {
                youtube = await Innertube.create({
                    lang: 'en',
                    location: 'US',
                    retrieve_player: false,
                });
            }
            const info = await youtube.getInfo(url);
            const transcriptData = await info.getTranscript();
            return transcriptData.transcript.content.body.initial_segments.map((segment) => segment.snippet.text);
        } catch (error) {
            console.error('Error fetching transcript:', error);
            throw error;
        }
    };

    try {
        const url = event.url;
        const transcript = await fetchTranscript(url);
        return {
            statusCode: 200,
            body: JSON.stringify(transcript),
        };
    } catch (error) {
        return {
            statusCode: 500,
            body: JSON.stringify({ error: 'Failed to fetch transcript', details: error.message }),
        };
    }
};
EOL

# Update package.json to specify Node.js version and set type to module
jq '.engines.node = ">=14.0.0" | .type = "module"' package.json > temp.json && mv temp.json package.json

# Create the deployment package
zip -r ../youtube-transcript-lambda.zip .

# Go back to the parent directory
cd ..

echo "Lambda function has been set up and packaged into youtube-transcript-lambda.zip"
echo "Please upload this zip file to your AWS Lambda function."
echo "Ensure your Lambda function uses Node.js 14.x or later runtime."
echo "Set the handler to 'index.handler' in the Lambda function configuration."
